function fv= proc_rSquareSigned(fv, varargin)
%PROC_RSQUARESIGNED - computes signed r^2 values (measure for discriminance)
%
%Synopsis:
%fv_rsqu= proc_rSquareSigned(fv, <opt>)
%fv_rsqu= proc_rSquareSigned(fv, fv2, <opt>)
%
%Arguments:
%   fv  - data structure of feature vectors
%   fv2 - (optional) data structure of feature vectors. If fv2 is
%              specified, fv and fv2 must have only a single class: The
%              function then computes the discriminability between the two
%              feature vectors.
%   opt - struct or property/value list of optional properties
%     .tolerateNans: observations with NaN value are skipped
%            (nanmean/nanstd are used instead of mean/std)
%     .valueForConst: constant feauture dimensions are assigned this
%            value. Default: NaN.
%     .multiclassPolicy: possible options: 'pairwise' (default), 
%           all-against-last', 'each-against-rest', or provide specified
%           pairs as an [nPairs x 2] sized matrix. 
%Returns:
%     fv_rsqu - data structute of signed r^2 values (one sample only)
%
%Description:
% Computes the r^2 value for each feature, multiplied by the sign of
% of r value. The r^2 value is a measure
% of how much variance of the joint distribution can be explained by
% class membership.
%
% SEE  proc_TTest, proc_rValues, proc_rSquare

fv = misc_history(fv);

if length(varargin)>0 & isstruct(varargin{1}),
  fv2= varargin{1};
  varargin= varargin(2:end);
  if size(fv.y,1)*size(fv2.y,1)>1,
    error('when using 2 data sets both may only contain 1 single class');
  end
  if strcmp(fv.className{1}, fv2.className{1}),
    fv2.className{1}= strcat(fv2.className{1}, '2');
  end
  fv= proc_appendEpochs(fv, fv2);
  clear fv2;
end

fv= proc_rValues(fv, varargin{:});
fv.x= fv.x .* abs(fv.x);
for cc= 1:length(fv.className),
  fv.className{cc}= ['sgn r^2' fv.className{cc}(2:end)];
end
fv.yUnit= 'sgn r^2';
