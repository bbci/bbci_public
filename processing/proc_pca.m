function [dat, opt] = proc_pca(dat, varargin)
%PROC_PCA - Principal Component Analysis
% [dat_pca, pca_opt] = proc_pca(dat, <opt>)
% 
%Synopsis for training PCA:
% [DAT_PCA_TRAIN, PCA_OPT] = proc_pca(DAT_TRAIN, <OPT>)
%
%Synopsis for applying PCA:
% DAT_PCA_TEST = proc_pca(DAT_TEST, PCA_OPT)
%
%Arguments:
% DAT_TRAIN     - data structure of continuous or epoched data
% OPT           - struct or property/value list of optional properties:
%  .whitening   - if 1, the output dimensions will all have unit variance
%                 (default 0)
% PCA_OPT       - a struct that contains: a bias vector, filters and field
%                 patterns of the sources
%
%Returns
% DAT_PCA_TRAIN,
% DAT_PCA_TEST  - updated data structure
% PCA_OPT       - a struct that contains: a bias vector, filters and field
%                 patterns of the sources
%

% Sven Daehne, 03.2011, sven.daehne@tu-berlin.de
% Matthias Schultze-Kraft, 12.2015, schultze-kraft@tu-berlin.de

props= {'whitening'         0       'BOOL'
        'filters'           []      'DOUBLE'
        'field_patterns'    []      'DOUBLE'
        'bias'              []      'DOUBLE'};

if nargin==0,
  dat = props; return
end

dat = misc_history(dat);
misc_checkType(dat, 'STRUCT(x clab y)');

opt = opt_proplistToStruct(varargin{:});
opt = opt_setDefaults(opt, props);
opt_checkProplist(opt, props);

[T,nChans,nEpos] = size(dat.x);

%% train PCA
if isempty(opt.filters) || isempty(opt.bias)
    % get the data matrix
    if ndims(dat.x)==3
        % since time structure does not matter, we can simply concatenate all
        % epochs to get one big data matrix
        X = permute(dat.x, [1,3,2]); % now channels are the last dimension
        X = reshape(X, [T*nEpos, nChans]);
    else
        X = dat.x;
    end
    % remove the mean here already
    b = mean(X,1);
    B = repmat(b, [T*nEpos, 1]);
    X = X - B;
    
    % perform PCA and compute whitening matrix
    C = cov(X);
    [V, D] = eig(C);
    [ev_sorted, sort_idx] = sort(diag(D), 'descend');
    V = V(:,sort_idx);
    D = diag(ev_sorted);
    
    if opt.whitening
        V = V * diag(diag(D).^-0.5);
    end
 
    opt.filters = V;
    opt.field_patterns = V';
    opt.eigenvalues = ev_sorted;
    opt.bias = b;

end

%% apply PCA
if not(length(opt.bias) == nChans)
    error('Dimension of bias must equal the number of channels!')
end
% make sure opt.bias is a row vector
if size(opt.bias, 1) > size(opt.bias,2)
    opt.bias = opt.bias';
end

% subtract bias, then apply filters
B = squeeze(repmat(opt.bias, [T,1,nEpos]));
dat.x = dat.x - B;
dat = proc_linearDerivation(dat, opt.filters);

