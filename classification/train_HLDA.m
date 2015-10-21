function C = train_HLDA(XTr, YTr, nSegments, varargin)
% TRAIN_HLDA - Hierarchical linear discriminant analysis 
%
%Synopsis:
%   C = train_HLDA(XTr, YTr, nSegments, varargin)
%
%Arguments:
%   XTR: DOUBLE [TxNxM] - Data matrix, with T temporal features, N
%                           N spatial features, and M 
%                           training points/examples. 
%   YTR: INT [CxM]      - Class membership labels of points in X_TR. C by M 
%                           matrix of training labels, with C representing 
%                           the number of classes and M the number of 
%                           training examples/points.
%                           YTR(i,j)==1 if the point j belongs to class i.
%   nSegments: INT      - the number of non-overlapping segments the interval
%                           should be separated in  
%   OPT: PROPLIST       - Structure or property/value list of optional
%                           properties. Options are also passed to clsutil_shrinkage.
%     'Regression'  - BOOL (default 0): If true, the top level classifier is
%                           a logistic regression classifier. 
%     'nChannels'   - INT (default 0): Used when using 'crossvalidation' in order to 
%                           reconstruct the 2D feature matrix to its original 3D
%                           [T x Ch x N] shape.
%Returns:
%   C: STRUCT           - Structure containing the trained classifiers for
%                           each segment and the final top level
%                           classifier. The structure C includes the fields:
%       'seg': STRUCT []      - contains a trained LDA classifier for each segment
%       'final': STRUCT       - the final top-level LDA classifier
%       'nChannels': INT      - (optional) the number of channels in the training data
%Description:
%   train_HLDA trains a hierarchical LDA classifier given training data,
%   labels and a number of segments. Either LDA (default) or logistic regression 
%   is used as a top-level classifier.
%
%   References:Gerson, A.D., Parra, L.C., Sajda, P.: Cortically coupled 
%   computer vision for rapid image search. IEEE Transactions on Neural 
%   Systems and Rehabilitation Engineering 14, 174–179 (2006).

%
%
%Examples:
%   train_HLDA(XTr, YTr, nSegments)
%   train_HLDA(XTr, YTr, nSegments, 'Regression', 1, 'nChannels', 64)
%   
%See also:
%   APPLY_HLDA


props= {'Regression'      0                             'BOOL'
        'nChannels'       0                             'INT'
       };


opt= opt_proplistToStruct(varargin{:});
[opt, isdefault]= opt_setDefaults(opt, props);
opt_checkProplist(opt, props);

% validate argument types
misc_checkType(XTr, 'DOUBLE');

if opt.nChannels ~= 0
  misc_checkType(XTr, 'DOUBLE[- -]');
end

misc_checkType(YTr, 'DOUBLE[2 -]');
misc_checkType(nSegments, 'INT');

dims = size(XTr);

% make data matrix 3D if it has been tranformed to 2D for crossvalidation
if (length(size(XTr)) == 2) && opt.nChannels > 0
  XTr = reshape(XTr, [], opt.nChannels, dims(2));
end

dims = size(XTr);

%boundary indices between segments
seg_idx = round(linspace(0, dims(1), nSegments+1));

seg_scores = zeros(nSegments, dims(end));

for i = 1:nSegments
    if length(size(XTr)) > 2
      seg = XTr(seg_idx(i) + 1 : seg_idx(i + 1), :, :); % i-th segment of X
      seg = reshape(seg, [], dims(end));
    else
      seg = XTr(seg_idx(i) + 1 : seg_idx(i + 1), :); % i-th segment of X
    end
    %train LDA classifier for this segment
    seg_LDA = train_RLDAshrink(seg, YTr, 'Scaling', 1);
    C.seg(i) = seg_LDA; 
    seg_scores(i,:) = apply_separatingHyperplane(seg_LDA, seg); %get classifier scores for segment
end

if opt.Regression
    %logistic regression as top-level classifier
    C.final.B = mnrfit(seg_scores', YTr');
else
    %LDA as top-level classifier
    C.final = train_RLDAshrink(seg_scores, YTr, 'Scaling', 1);
end

% add number of channels to classifier so they can be used in the apply function
if opt.nChannels > 0
  C.nChannels = opt.nChannels;
end
