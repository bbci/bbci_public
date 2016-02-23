function fv_aucval= proc_aucValues(fv, varargin)
%PROC_AUCVALUES - Computes the area under the curve (AUC) score for each feature
%
%Synopsis:
% FV_AUC= proc_aucValues(FVL)
%
%Arguments:
% FV - data structure of feature vectors of two classes
%
%Returns:
% FV_AUC - data structure of auc values
%  .x     - area under the curve scores shifted and scaled to be in [-1 1],
%           i.e. fv_auc.x = (auc-0.5)*2
%  .se    - contains the standard error of fv_auc.x, if opt.Stats==1
%  .p     - contains the p value of null hypothesis that the auc is 0.5, 
%           if opt.Stats==1.
%           if opt.Bonferroni==1, the p-value is multiplied by
%           fv_auc.corrfac
%  .sgnlogp - contains the signed log10 p-value, if opt.Stats==1
%           if opt.Bonferroni==1, the p-value is multiplied by
%           fv_auc.corrfac and then logarithmized
%  .sigmask - binary array indicating significance at alpha level
%             opt.Alphalevel, if opt.Stats==1 and opt.Alphalevel > 0
%  .corrfac - Bonferroni correction factor (number of simultaneous tests), 
%             if opt.Bonferroni==1
%
%Properties:
% 'Stats' - if true, additional statistics are calculated, including the
%           standard error, the p-value for the null 
%           Hypothesis that the area under the curve is 0.5,
%           and the "signed log p-value"
% 'Bonferroni' - if true, Bonferroni corrected is used to adjust p-values
%                and their logarithms
% 'Alphalevel' - if provided, a binary indicator of the significance to the
%                alpha level is returned for each feature in fv_auc.sigmask
% 
% Description
%  Computes the area under the curve (AUC) score for each feature.
%
%Examples:
%  [cnt, mrk]= file_readBV(some_file);   %load EEG-data in BV-format
%  mrk= mrk_defineClasses(mrk, {1, 2; 'target','nontarget'}); 
%  epo= proc_segmentation(cnt, mrk, [-200 800], 'CLab', {'Fz','Cz','Pz'});
%  epo_auc = proc_aucValues(epo);
%
%
%See also: proc_rSquareSigned, proc_rValues, proc_classmeanDiff

% 09-2012 stefan.haufe@tu-berlin.de
% 07-2012 Johannes Hoehne   - Updated the help documentation & probs

props= {'Stats'         0    '!BOOL'
        'Bonferroni'    0    '!BOOL'
        'Alphalevel'    []   'DOUBLE'
       };
props_mcdiff= procutil_multiclassDiff;

if nargin==0,
  fv_aucval= cat(3, props, props_mcdiff); return
end

fv= misc_history(fv);
misc_checkType(fv, 'STRUCT(x y)');

opt= opt_proplistToStruct(varargin{:});
[opt, isdefault]= opt_setDefaults(opt, props);
opt_checkProplist(opt, props, props_mcdiff);

if size(fv.y,1)>2,
  opt_mcdiff= opt_substruct(opt, props_mcdiff);
  fv_aucval= procutil_multiclassDiff(fv, {@proc_aucValues,opt}, opt_mcdiff);
  return;
end

sz= size(fv.x);
fv.x= reshape(fv.x, [prod(sz(1:end-1)), sz(end)]);

fv_aucval = fv;
fv_aucval.x = zeros(prod(sz(1:end-1)), 1);

if opt.Bonferroni
  fv_aucval.corrfac = prod(sz(1:end-1));
end

for ii = 1:prod(sz(1:end-1))
    [p, h, stats] = ranksum(fv.x(ii, find(fv.y(1, :)))', fv.x(ii, find(fv.y(2, :)))');
    fv_aucval.x(ii) = (stats.ranksum-(sum(fv.y(1,:))*(sum(fv.y(1,:))+1)/2))/prod(sum(fv.y'));
    if opt.Stats
      fv_aucval.p(ii) = p;
      if opt.Bonferroni
        fv_aucval.sgnlogp(ii) = -((log(2)+normcdfln(-abs(stats.zval)))./log(10)+abs(log10(fv_aucval.corrfac)))*sign(stats.zval);
      else
        fv_aucval.sgnlogp(ii) = -((log(2)+normcdfln(-abs(stats.zval)))./log(10))*sign(stats.zval);
      end 
    end
end

if length(sz) > 2 
    fv_aucval.x= reshape(fv_aucval.x, sz(1:end-1));
end

fv_aucval.x = (fv_aucval.x-0.5)*2;
if opt.Stats
  fv_aucval.se = 2*repmat(sqrt((0.25 + (sum(sum(fv.y'))-2)*(1/12))./prod(sum(fv.y'))), sz(1:end-1));
  fv_aucval.p = reshape(fv_aucval.p, sz(1:end-1));
  fv_aucval.sgnlogp = reshape(fv_aucval.sgnlogp, sz(1:end-1));
  if opt.Bonferroni
    fv_aucval.p = min(fv_aucval.p*fv_aucval.corrfac, 1);
  end  
%   fv_aucval.sgnlogp = -log10(fv_aucval.p).*sign(fv_aucval.x);
  if ~isempty(opt.Alphalevel)
    fv_aucval.alphalevel = opt.Alphalevel;
    fv_aucval.sigmask = fv_aucval.p < opt.Alphalevel;
  end
end

if isfield(fv, 'className'),
  fv_aucval.className= {sprintf('auc( %s , %s )', fv.className{1:2})};
end
fv_aucval.y= 1;
fv_aucval.yUnit= 'auc score';
fv_aucval.indexedByEpochs = {}; 
