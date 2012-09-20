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
%
%Properties:
% 'Stats' - if true, additional statistics are calculated, including the
%           standard error of the mean, the p-value for the null 
%           Hypothesis that the mean is zero, and the "signed log p-value"
% 
% Description
%  Computes the area under the curve (AUC) score for each feature.
%
%Examples:
%  [cnt, mrk]= file_readBV(some_file);   %load EEG-data in BV-format
%  mrk= mrk_defineClasses(mrk, {1, 2; 'target','nontarget'}); 
%  epo= proc_segmentation(cnt, mrk, [-200 800], 'CLab', {'Fz','Cz','Pz'});
%  epo_auc = proc_auc_values(epo);
%
%
%See also:  proc_tTest, proc_rSquare, proc_rValues

% 09-2012 stefan.haufe@tu-berlin.de
% 07-2012 Johannes Hoehne   - Updated the help documentation & probs

props= { 'Stats',             0,           '!BOOL'};

if nargin==0,
  fv_rval= props; return
end

fv = misc_history(fv);
misc_checkType(fv, 'STRUCT(x y)');

opt= opt_proplistToStruct(varargin{:});
[opt, isdefault]= opt_setDefaults(opt, props);
opt_checkProplist(opt, props);

sz= size(fv.x);
fv.x= reshape(fv.x, [prod(sz(1:end-1)), sz(end)]);

fv_aucval = fv;
fv_aucval.x = zeros(prod(sz(1:end-1)), 1);
for ii = 1:prod(sz(1:end-1))
    [p, h, stats] = ranksum(fv.x(ii, find(fv.y(1, :)))', fv.x(ii, find(fv.y(2, :)))');
    fv_aucval.x(ii) = (stats.ranksum-(min(sum(fv.y'))*(min(sum(fv.y'))+1)/2))/prod(sum(fv.y'));
    if opt.Stats
      fv_aucval.p(ii) = p;
      fv_aucval.sgnlogp(ii) = -((log(2)+normcdfln(-abs(stats.zval)))./log(10))*sign(stats.zval);
    end
end

fv_aucval.x= reshape(fv_aucval.x, sz(1:end-1));
if opt.Stats
  fv_aucval.se = repmat(sqrt((0.25 + (sum(sum(fv.y'))-2)*(1/12))./prod(sum(fv.y'))), sz(1:end-1));
  fv_aucval.p = reshape(fv_aucval.p, sz(1:end-1));
  fv_aucval.sgnlogp = reshape(fv_aucval.sgnlogp, sz(1:end-1));
  if exist('mrk_addIndexedField')==2,
    %% The following line is only to be executed if the BBCI Toolbox
    %% is loaded.
    fv_aucval= mrk_addIndexedField(fv_aucval, 'se');
    fv_aucval= mrk_addIndexedField(fv_aucval, 'p');
    fv_aucval= mrk_addIndexedField(fv_aucval, 'sgnlogp');
  end
end

if isfield(fv, 'className'),
  fv_aucval.className= {sprintf('auc( %s , %s )', fv.className{1:2})};
end
fv_aucval.y= 1;
fv_aucval.yUnit= 'auc';
