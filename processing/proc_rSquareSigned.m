function fv= proc_rSquareSigned(fv, varargin)
%PROC_RSQUARESIGNED - computes signed r^2 values (measure for discriminance)
%
%Synopsis:
% 	fv = proc_rSquareSigned(fv, <opt>)
%
%Returns:
% FV_RVAL - data structure of signed squared biserial correlation coefficients
%  .x     - signed squared biserial correlation between each featur and the 
%           class label
%  .se    - contains the standard error of atanh(r), if opt.Stats==1
%  .p     - contains the p value of null hypothesis that there is zero
%           correlation between feature and class-label, if opt.Stats==1
%  .sgnlogp - contains the signed log10 p-value, if opt.Stats==1
%             if opt.Bonferroni==1, the p-value is multiplied by
%             fv_rval.corrfac
%  .sgnlogp - contains the signed log10 p-value, if opt.Stats==1
%           if opt.Bonferroni==1, the p-value is multiplied by
%           fv_rval.corrfac and then logarithmized
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
%Description:
% Computes the r^2 value for each feature, multiplied by the sign of
% of r value. The r^2 value is a measure
% of how much variance of the joint distribution can be explained by
% class membership.
%
% Example:
%  [cnt, mrk]= file_readBV(some_file);   %load EEG-data in BV-format
%  mrk= mrk_defineClasses(mrk, {1, 2; 'target','nontarget'}); 
%  epo= proc_segmentation(cnt, mrk, [-200 800], 'CLab', {'Fz','Cz','Pz'});
%  epo_r = proc_rSquareSigned(epo);
%
% See also proc_classmeanDiff, proc_rValues, proc_rSquare
%
% 03-03 Benjamin Blankertz
% 09-2012 stefan.haufe@tu-berlin.de

if nargin==0,
  fv=proc_rValues; return
end

fv= proc_rValues(fv, varargin{:});
fv.x= fv.x .* abs(fv.x);
for cc= 1:length(fv.className),
  fv.className{cc}= ['sgn r^2' fv.className{cc}(2:end)];
end
fv.yUnit= 'sgn r^2';
