function fv= proc_rSquare(fv, varargin)
%PROC_RSQUARE - computes r^2 values (measure for discriminance)
%
%Synopsis:
% 	fv = proc_rSquare(fv, <opt>)
%
%Returns:
% FV_RVAL - data structure of squared biserial correlation coefficients 
%  .x     - squared biserial correlation between each feature and the class label
%  .se    - standard error of atanh(r), if opt.Stats==1
%  .p     - p value of null hypothesis that there is zero
%           correlation between feature and class-label, if opt.Stats==1
%  .sgnlogp - contains the signed log10 p-value, if opt.Stats==1
%             if opt.Bonferroni==1, the p-value is multiplied by
%             fv_rval.corrfac
%  .sgnlogp - contains the signed log10 p-value, if opt.Stats==1
%           if opt.Bonferroni==1, the p-value is multiplied by
%           fv_rval.corrfac, cropped, and then logarithmized
%  .sigmask - binary array indicating significance at alpha level
%             opt.Alphalevel, if opt.Stats==1 and opt.Alphalevel > 0
%  .corrfac - Bonferroni correction factor (number of simultaneous tests), 
%             if opt.Bonferroni==1
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
% 'Bonferroni' - if true, Bonferroni corrected is used to adjust p-values
%                and their logarithms
% 'Alphalevel' - if provided, a binary indicator of the significance to the
%                alpha level is returned for each feature in fv_rval.sigmask
% 
%Description
% Computes the r^2 value for each feature. The r^2 value is a measure
% of how much variance of the joint distribution can be explained by
% class membership.
%
% See also proc_classmeanDiff, proc_rValues, proc_rSquareSigned
%
% 03-03 Benjamin Blankertz
% 09-2012 stefan.haufe@tu-berlin.de

if nargin==0,
  fv=proc_rValues; return
end

fv= proc_rValues(fv, varargin{:});
fv.x= fv.x.^2;
for cc= 1:length(fv.className),
  fv.className{cc}= ['r^2' fv.className{cc}(2:end)];
end
fv.yUnit= 'r^2';

