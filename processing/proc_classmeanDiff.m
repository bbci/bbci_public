function fv_diff=proc_classmeanDiff(fv, varargin)
% FV_DIFF - calculates the pointwise difference between class means.
%
%Synopsis:
% FV_DIFF= proc_classmeanDiff(FV, 'Property',Value, ...)
%
%Arguments:
% FV - data structure of feature vectors
%
%Returns:
% FV_DIFF - data structure of class mean differences
%  .x     - difference of the class means for each feature and class
%           combination
%  .se    - standard error of the difference, if opt.Stats==1
%  .tstat - Student t statistics of the difference, if opt.Stats==1
%  .df    - degrees of freedom of the t distribution (two sample test)
%  .p     - p value of null hypothesis that the difference is zero, 
%           derived from t Statistics using two-sided test, if opt.Stats==1
%           If opt.Bonferroni==1, the p-value is multiplied by
%           fv_diff.corrfac and cropped at 1.
%  .sgnlogp - signed log10 p-value, if opt.Stats==1
%           If opt.Bonferroni==1, the p-value is multiplied by
%           fv_diff.corrfac, cropped, and then logarithmized.
%  .sigmask - binary array indicating significance at alpha level
%             opt.Alphalevel, if opt.Stats==1 and opt.Alphalevel > 0
%  .crit    - 'significance' threshold of t Statistics with respect to 
%             level alpha
%  .corrfac - Bonferroni correction factor (number of simultaneous tests), 
%             if opt.Bonferroni==1
%
%Properties:
% 'Stats' - if true, additional statistics are calculated, including the
%           standard error of the difference, the t score, the p-value 
%           for the null Hypothesis that the difference is zero, 
%           and the "signed log p-value"
% 'Bonferroni' - if true, Bonferroni corrected is used to adjust p-values
%                and their logarithms
% 'Alphalevel' - if provided, a binary indicator of the significance to the
%                alpha level is returned for each feature in fv_diff.sigmask
% 
%
%Examples:
%  [cnt, mrk]= file_readBV(some_file);   %load EEG-data in BV-format
%  mrk= mrk_defineClasses(mrk, {1, 2; 'target','nontarget'}); 
%  epo= proc_segmentation(cnt, mrk, [-200 800], 'CLab', {'Fz','Cz','Pz'});
%  epo_r = proc_classmeanDiff(epo);
%
%See also:  proc_average, proc_aucValues, proc_rValues, proc_rSquareSigned
% Benjamin Blankertz
% 09-2012 stefan.haufe@tu-berlin.de

props= {  'Stats'      0    '!BOOL';
          'Bonferroni' 0    '!BOOL';
          'Alphalevel' []   'DOUBLE'};

if nargin==0,
  out = props; return
end

misc_checkType(fv, 'STRUCT(x y)'); 
if nargin==2 && isnumeric(varargin{2})
  opt.Classes = varargin{2};
else
  opt= opt_proplistToStruct(varargin{:});
end
[opt, isdefault]= opt_setDefaults(opt, props);
opt_checkProplist(opt, props);        
fv = misc_history(fv);

nClasses= size(fv.y, 1);
if nClasses==1,
  warning('1 class only: calculating differences against flat-line of same var', 'r_policy')
  fv2= fv;
  szx= size(fv.x);
  fv2.x= fv2.x - repmat(mean(fv2.x,3), [1 1 size(fv2.x,3)]);
  fv2.className= {'flat'};
  fv= proc_appendEpochs(fv, fv2);
elseif nClasses>2,
  warning('calculating pairwise differences');
%   state= util_warning('off', 'selection');
  combs= fliplr(nchoosek(1:size(fv.y,1), 2));
  for ic= 1:length(combs),
    ep= proc_selectClasses(fv, combs(ic,:));
    if ic==1,
      fv_diff= proc_classmeanDiff(ep, varargin);   
      ndims = length(size(ep.x));
      if ndims > 3
        fv_diff.ndims = ndims;
      end
    else
      fv_diff= proc_appendEpochs(fv_diff, proc_classmeanDiff(ep, varargin));
    end
  end
%   util_warning(state);
  return; 
end

sz= size(fv.x);
fv.x= reshape(fv.x, [prod(sz(1:end-1)) sz(end)]);

c1= find(fv.y(1,:));
c2= find(fv.y(2,:));
N1= length(c1);
N2= length(c2);

dont_copy= {'x','y','className'};
fv_diff = rmfield(fv, dont_copy);

fv_diff.x = reshape(mean(fv.x(:,c1),2)-mean(fv.x(:,c2),2), sz(1:end-1));
if opt.Stats 
  [h, p, ci, stats] = ttest2(fv.x(:,c1)', fv.x(:,c2)', [], [], 'equal');
  fv_diff.se = reshape(sqrt(stats.sd.^2/N1 + stats.sd.^2/N2), sz(1:end-1));  
  fv_diff.p = reshape(p, sz(1:end-1));
  fv_diff.tstat = reshape(stats.tstat, sz(1:end-1));
  fv_diff.df = stats.df(1);
  if opt.Bonferroni
    fv_diff.corrfac = prod(sz(1:end-1));
    fv_diff.p = min(fv_diff.p*fv_diff.corrfac, 1);
  end  
  fv_diff.sgnlogp = -log10(fv_diff.p).*sign(fv_diff.x);
  if ~isempty(opt.Alphalevel)
    fv_diff.alphalevel = opt.Alphalevel;
    fv_diff.sigmask = fv_diff.p < opt.Alphalevel;
    fv_diff.crit = stat_calcTCrit(opt.Alphalevel, stats.df(1));
  end
end

fv_diff.y= 1;
fv_diff.className= {sprintf('%s - %s', fv.className{1:2})};
fv_diff.indexedByEpochs = {};

