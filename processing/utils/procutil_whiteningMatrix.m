function M = procutil_whiteningMatrix(X, varargin)
% PROCUTIL_WHITENINGMATRIX - Computes whitening/dim-reduction matrix. 
%
%Synopsis:
% M = procutil_whiteningMatrix(X, <OPT>)
%
%Arguments:
%  X:   data matrix, of size [n_samples, n_channels, <n_epos>], where
%       n_epos can be 1
%
%  OPT: struct or property/value list of optional properties
%   'C': Covariance matrix. Default is [], i.e. it will be computed based
%           on X
%
%Returns:
%  M: whitening matrix. The (PCA-)whitening filters are in the columns.
%       Thus cov(M'*X) will be the identity matrix. Note that the number of
%       columns depends on a rank-test. We define the rank as the index of 
%       the last eigenvalue that is larger than a certain fraction of the 
%       largest eigenvalue. 
%

% Author(s): Sven Daehne


props= {'C'  []     'DOUBLE[- -]'};

if nargin==0,
  M = props; return
end

opt = opt_proplistToStruct(varargin{:});
opt = opt_setDefaults(opt, props);
opt_checkProplist(opt, props);     

% get/compute the covariance matrix
if isempty(opt.C)
    misc_checkType(X, 'DOUBLE[2- 2-]|DOUBLE[2- 2- -]');
    if ndims(X) == 3
        [n_samples, n_channels, n_epos] = size(X);
        X = reshape(permute(X, [1,3,2]), [n_samples*n_epos, n_channels]);
    end
    C = cov(X);
else
    C = opt.C;
end

% perform PCA based on eigen-decomposition of the covariance matrix
[V, D] = eig(C);
[ev_sorted, sort_idx] = sort(diag(D), 'descend');
V = V(:,sort_idx);
D = diag(ev_sorted);

% Compute an estimate of the rank of the data
% Note how the rank is defined here: We define it as the index of the last
% eigenvalue that is larger than a certain fraction of the largest
% eigenvalue. 
tol = ev_sorted(1) * 10^-10; % the fraction of the first, i.e. largest eigenvalue
r = find(ev_sorted > tol, 1, 'last'); % the index of the last eigenvalue that is 
                                        % larger than the tolerance

% construct the whitening matrix
M = V * diag(diag(D).^-0.5); 
% reduce to r columns
M = M(:, 1:r);
