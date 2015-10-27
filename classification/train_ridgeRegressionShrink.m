function C = train_ridgeRegressionShrink(xTr, yTr, varargin)
% TRAIN_RIDGEREGRESSIONSHRINK - Regularized Regression with automatic shrinkage selection
%
%Synopsis:
%   C = train_ridgeRegressionShrink(XTR, YTR)
%   C = train_ridgeRegressionShrink(XTR, YTR, OPTS)
%
%Arguments:
%   XTR: DOUBLE [NxM] - Data matrix, with N feature dimensions, and M training points/examples. 
%   YTR: INT [CxM] - Regression targets. C by M matrix of regression
%                     labels, with C representing the number of target signals and M the number of training examples/points.
%   OPT: PROPLIST - Structure or property/value list of optional
%                   properties. Options are also passed to clsutil_shrinkage.
%     'ExcludeInfs' - BOOL (default 0): If true, training data points with value 'inf' are excluded from XTR
%
%Returns:
%   C: STRUCT - Trained regressor structure, with the hyperplane given by
%               fields C.w and C.b.  C includes the fields:
%    'w' : weight matrix
%    'b' : FLOAT bias
%
%Description:
%   TRAIN_RLDA trains a regularized linear regressionon data X with
%   regression targets given in YTR. The shrinkage parameter is selected by the
%   function clsutil_shrinkage.
%
%
%Examples:
%   train_RLDA(X, regression_target)
%   train_RLDA(X, regression_target, 'Target', 'D')
%   
%See also:
%   APPLY_SEPARATINGHYPERPLANE, CLSUTIL_SHRINKAGE, 
%   TRAIN_LDA, TRAIN_RDAREJECT

% Sven Daehne


props= {'ExcludeInfs'      0                             'BOOL'
       };
   
% get props list of the subfunction
props_shrinkage= clsutil_shrinkage;

if nargin==0,
  C= opt_catProps(props, props_shrinkage); 
  return
end

opt = opt_proplistToStruct(varargin{:});
opt = opt_setDefaults(opt, props);
opt_checkProplist(opt, props, props_shrinkage);

if opt.ExcludeInfs,
  ind = find(sum(abs(xTr),1)==inf);
  xTr(:,ind) = [];
  yTr(:,ind) = [];
end

% compute the regularized covariance matrix 
opt_shrinkage = opt_substruct(opt, props_shrinkage(:,1));
[C_cov, C.gamma] = clsutil_shrinkage(xTr, opt_shrinkage);

% compute the weight vector(s)
C.w = C_cov \ xTr * yTr';

% normalize the length of the weight vector(s) such that the estimated y
% have the same scaling (standard deviation) as the target y
y_est = C.w' * xTr;
for k=1:size(C.w,2)
    C.w(:,k) = std(yTr(k,:)) * C.w(:,k) / std(y_est(k,:));
end

% compute the bias term(s)
mu_x = mean(xTr,2);
mu_y = mean(yTr,2);
C.b = mu_y - C.w'*mu_x;


