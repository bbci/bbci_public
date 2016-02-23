function [dat, varargout]= proc_csp(dat, varargin)
%PROC_CSP - Common Spatial Pattern (CSP) Analysis
%
%Synopsis:
% [DAT, CSP_W, CSP_A, SCORE]= proc_cspAuto(DAT, <OPT>);
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

props= {'CovFcn'      {@cov}                         '!FUNC|CELL'
        'ScoreFcn'    {@procutil_scoreEigenvalues}   '!FUNC|CELL'
        'SelectFcn'   {@procutil_selectMinMax, 3}    '!FUNC|CELL'
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
M = procutil_whiteningMatrix([], mean(C,3));

% Do actual CSP computation as generalized eigenvalue decomposition in
% whitened space
% [W, D]= eig( M'*diff(C, 1, 3)*M , M'*mean(C,3)*M );
[W, D]= eig(M'*diff(C, 1, 3)*M);
W = M*W; % project filters from whitened space back into original channel space

% % Do actual CSP computation as generalized eigenvalue decomposition
% [W, D]= eig( C(:,:,2), C(:,:,1)+C(:,:,2) );

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

% Prepare output and return it
varargout= {dat};
if nargout>1,
  varargout{2}= W;
end
if nargout>2,
  % do the inversion only if requested
  A= pinv(W)';
  varargout{3}= A;
end
if nargout>3,
  varargout{4}= score;
end
