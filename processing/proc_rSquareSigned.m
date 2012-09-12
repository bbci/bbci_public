function fv= proc_rSquareSigned(fv, varargin)
%PROC_RSQUARESIGNED - computes signed r^2 values (measure for discriminance)
%
%Synopsis:
% 	fv = proc_rSquareSigned(fv, <opt>)
%
%Arguments:
%   fv:     STRUCT   - data structure of feature vectors
%   opt:    PROPLIST - struct or property/value list of optional properties
%     'TolerateNans' - observations with NaN value are skipped
%            (nanmean/nanstd are used instead of mean/std)
%     'ValueForConst' - constant feauture dimensions are assigned this
%            value. Default: NaN.
%     'MulticlassPolicy' - possible options: 'pairwise' (default), 
%           all-against-last', 'each-against-rest', or provide specified
%           pairs as an [nPairs x 2] sized matrix. 
%Returns:
%   fv: data structure with x-field containing signed r^2 values (one sample only)
%
%Description:
% Computes the r^2 value for each feature, multiplied by the sign of
% of r value. The r^2 value is a measure
% of how much variance of the joint distribution can be explained by
% class membership.
%
% See also proc_rValues, proc_rSquare
if nargin==0,
  fv=proc_rValues; return
end

fv= proc_rValues(fv, varargin{:});
fv.x= fv.x .* abs(fv.x);
for cc= 1:length(fv.className),
  fv.className{cc}= ['sgn r^2' fv.className{cc}(2:end)];
end
fv.yUnit= 'sgn r^2';
