function fv= proc_rSquare(fv, varargin)
%PROC_RSQUARE - computes r^2 values (measure for discriminance)
%
%Synopsis:
% 	fv = proc_rSquare(fv, <opt>)
%
%Arguments:
%   FV:     STRUCT   - data structure of feature vectors
%   OPT:    PROPLIST - struct or property/value list of optional properties
%     'TolerateNans' - observations with NaN value are skipped
%            (nanmean/nanstd are used instead of mean/std)
%     'ValueForConst' - constant feauture dimensions are assigned this
%            value. Default: NaN.
%     'MulticlassPolicy' - possible options: 'pairwise' (default), 
%           all-against-last', 'each-against-rest', or provide specified
%           pairs as an [nPairs x 2] sized matrix. 
%
%Properties:
% 'TolerateNans': observations with NaN value are skipped
%    (nanmean/nanstd are used instead of mean/std). Deafult: 0
% 'ValueForConst': constant feauture dimensions are assigned this
%    value. Default: NaN.
% 'MulticlassPolicy': possible options: 'pairwise' (default), 
%    'all-against-last', 'each-against-rest', or provide specified
%    pairs as an [nPairs x 2] sized matrix. ('specified_pairs' is obsolete)
% 'Stats' - if true, additional statistics are calculated, including the
%           standard error of atanh(r), the p-value for the null 
%           Hypothesis that the correlation is zero, 
%           and the "signed log p-value"
%
%Returns:
%   fv: data structure with x-field containing r^2 values 
%  .se    - contains the standard error of atanh(r), if opt.Stats==1
%  .p     - contains the p value of null hypothesis that there is zero
%           correlation between feature and class-label, if opt.Stats==1
%  .sgnlogp - contains the signed log10 p-value, if opt.Stats==1
%
%Description:
% Computes the r^2 value for each feature. The r^2 value is a measure
% of how much variance of the joint distribution can be explained by
% class membership.
%
% See also proc_rValues, proc_rSquareSigned

% 03-03 Benjamin Blankertz
if nargin==0,
  fv=proc_rValues; return
end

fv= proc_rValues(fv, varargin{:});
fv.x= fv.x.^2;
for cc= 1:length(fv.className),
  fv.className{cc}= ['r^2' fv.className{cc}(2:end)];
end
fv.yUnit= 'r^2';

