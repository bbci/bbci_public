function C = train_LDA(xTr, yTr, varargin)
% TRAIN_LDA - linear discriminant analysis 
%
%Synopsis:
%   C = train_LDA(XTR, YTR)
%   C = train_LDA(XTR, YTR, OPTS)
%
%Arguments:
%   XTR: DOUBLE [NxM] - Data matrix, with N feature dimensions, and M training points/examples. 
%   YTR: INT [CxM] - Class membership labels of points in X_TR. C by M matrix of training
%                     labels, with C representing the number of classes and M the number of training examples/points.
%                     Y_TR(i,j)==1 if the point j belongs to class i.
%   OPT: PROPLIST - Structure or property/value list of optional
%                   properties. Options are also passed to clsutil_shrinkage.
%     'ExcludeInfs' - BOOL (default 0): If true, training data points with value 'inf' are excluded from XTR
%     'Prior' - DOUBLE (default ones(nClasses, 1)/nClasses): Empirical class priors
%     'StorePrior' - BOOL (default 0): If true, the prior will be stored with the classifier in C.prior
%     'Scaling' - BOOL (default 0): scale projection vector such that the distance between
%        the projected means becomes 2. Scaling only implemented for 2 classes so far. Using Scaling=1 will disable the use of a prior.
%     'StoreMeans' - BOOL (default 0): If true, the classwise means of the feature vectors
%        are stored in the classifier structure C. This can be used, e.g., for bbci_adaptation_pmean
%     'UsePcov' - BOOL (default 0): If true, the pooled covariance matrix is used instead of the average classwise covariance matrix.
%     'StoreCov',  - BOOL (default 0): If true, the covariance matrix will be stored with the classifier in C.cov
%     'StoreInvcov' - BOOL (default 0): If true, the inverse of the covariance matrix is stored in
%        the classifier structure C. This can be used, e.g., for bbci_adaptation_pcovmean
%     'StoreExtinvcov' - BOOL (default 0): If true, the extended inverse of the covariance will be stored with the classifier in C.extinvcov
%
%Returns:
%   C: STRUCT - Trained classifier structure, with the hyperplane given by
%               fields C.w and C.b.  C includes the fields:
%    'w' : weight matrix
%    'b' : FLOAT bias
%    'prior' : (optional) classwise priors
%    'means' :  (optional) classwise means
%    'cov' :  (optional) covariance matrix
%    'invcov' :  (optional) inverse of the covariance matrix
%    'extinvcov' : (optional) extended inverse of the covariance matrix
%
%Description:
%   TRAIN_RLDA trains a LDA classifier on data X with class
%   labels given in LABELS. 
%
%Examples:
%   train_LDA(X, labels)
%   
%See also:
%   APPLY_SEPARATINGHYPERPLANE

opt = opt_proplistToStruct(varargin{:});
opt.Gamma = 0;
C = train_RLDAshrink(xTr, yTr, opt);
