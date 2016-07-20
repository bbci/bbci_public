function [dat, varargout]= proc_csp(dat, varargin)
%PROC_CSP - Common Spatial Pattern (CSP) Analysis
%
%Synopsis:
% [DAT, CSP_W, CSP_A, SCORE]= proc_csp(DAT, <OPT>);
%
%Arguments:
% DAT - data structure of epoched data
% OPT - struct or property/value list of optional properties:
%  'CovFcn' - Handle of a function to estimate a covariance matrix.
%             Can also be a CELL {@FCN, PARAM1, PARAM2, ...} that
%             provides further arguments to that function.
%             Default: @cov
%             Other options, e.g., @procutil_covShrinkage
%  'ScoreFcn' - Handle of a function that calculates a score of
%               the extracted components.
%               Can also be a CELL {@FCN, PARAM1, PARAM2, ...}.
%               Default: @procutil_score_eigenvalues
%               Other options, e.g., @procutil_score_ratioOfMedians
%  'SelectFcn' - Handle of a function that selects a subset of the
%                extracted components.
%                Can also be a CELL {@FCN, PARAM1, PARAM2, ...}.
%                Default: {@procutil_selectMinMax, 3}
%                Other options, e.g., {@procutil_selectMaxAbs, 6}
%  'Verbose' - Print warnings and other output if larger than 0. Default 1
% 
%Returns:
% DAT   - updated data structure
% CSP_W - CSP projection matrix (spatial filters, in the columns)
% CSP_A - estimated mixing matrix (activation patterns, in the columns)
% SCORE - score of each CSP component
%
%Description:
% calculate common spatial patterns (CSP).
% please note that this preprocessing uses label information. so for
% estimating a generalization error based on this processing, you must
% not apply csp to your whole data set and then do cross-validation
% (csp would have used labels of samples in future test sets).
% you should use the .proc (train/apply) feature in xvalidation, see
% demos/demo_validation_csp
%
%See also demos/demo_validate_csp

props= {'CovFcn'      {@cov}                            '!FUNC|CELL'
        'ScoreFcn'    {@score_eigenvalues}              '!FUNC|CELL'
        'SelectFcn'   {@cspselect_equalPerClass, 3}     '!FUNC|CELL'
        'Verbose'     1                                 'INT'
       };

if nargin==0,
  dat= props; return
end

misc_checkType(dat, 'STRUCT(x y)'); 
misc_checkType(dat.y, 'DOUBLE[2 -]', 'dat.y');    % two classes only
opt= opt_proplistToStruct(varargin{:});
opt= opt_setDefaults(opt, props);
opt_checkProplist(opt, props);
dat= misc_history(dat);

nChans= size(dat.x, 2);

% Calculate classwise covariance matrices
[covFcn, covPar]= misc_getFuncParam(opt.CovFcn);
C= zeros(nChans, nChans, 2);
for k= 1:2,
  idx= find(dat.y(k,:));
  X= permute(dat.x(:,:,idx), [1 3 2]);
  X= reshape(X, [], nChans);
  C(:,:,k)= covFcn(X, covPar{:});
end

% get the whitening matrix
M = procutil_whiteningMatrix([], 'C', mean(C,3));
if (opt.Verbose > 0) && (size(M,2) < nChans)
    warning('Due to dimensionality reduction a maximum of only %d CSP components can be computed', size(M,2))
end

% Do actual CSP computation as generalized eigenvalue decomposition in
% whitened space
[W, D]= eig(M'*(C(:,:,1)-C(:,:,2))*M);
W = M*W; % project filters from whitened space back into original channel space
[ev, sort_idx] = sort(diag(D), 'ascend');
D = diag(ev);
W = W(:,sort_idx);

% ORIGINAL CODE FOR COMPUTING CSP IN CHANNEL SPACE
% % Do actual CSP computation as generalized eigenvalue decomposition
% [W, D]= eig( C(:,:,1)-C(:,:,2), C(:,:,1)+C(:,:,2) );

% Calculate score for each CSP channel
[scoreFcn, scorePar]= misc_getFuncParam(opt.ScoreFcn);
score= scoreFcn(dat, W, D, scorePar{:});

% Select desired CSP filters
[selectFcn, selectPar]= misc_getFuncParam(opt.SelectFcn);
idx= selectFcn(score, W, selectPar{:});
W= W(:,idx);
score= score(idx);

% Save old channel labels
if isfield(dat, 'clab'),
  dat.origClab= dat.clab;
end

% Apply CSP filters to time series
dat= proc_linearDerivation(dat, W, 'prependix','csp');

% Determine patterns according to [Haufe et al, Neuroimage, 87:96-110, 2014]
% http://dx.doi.org/10.1016/j.neuroimage.2013.10.067
C_avg = mean(C,3);
A= C_avg * W / (W'*C_avg*W);

varargout= {W, A, score};
