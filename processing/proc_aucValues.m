function fv_rval= proc_aucValues(fv)
%PROC_AUCVALUES - Computes the area under the curve (AUC) score for each feature
%
%Synopsis:
% FV_AUC= proc_aucValues(FVL)
%
%Arguments:
% FV - data structure of feature vectors
%
%Returns:
% FV_AUC - data structute of auc values (one sample only)
% 
% Description
%  Computes the area under the curve (AUC) score for each feature.
%
%Examples:
%  [cnt, mrk]= eegfile_readBV(some_file);   %load EEG-data in BV-format
%  mrk= mrk_defineClasses(mrk, {1, 2; 'target','nontarget'}); 
%  epo= proc_segmentation(cnt, mrk, [-200 800], 'CLab', {'Fz','Cz','Pz'});
%  epo_auc = proc_auc_values(epo);
%
%
%See also:  proc_t_scaled, proc_r_square, proc_r_values, proc_wr_multiclass_diff
%
% stefan.haufe@tu-berlin.de, 2012
% 07-2012 Johannes Hoehne   - Updated the help documentation & probs
fv = misc_history(fv);

misc_checkType('fv', 'STRUCT(x clab fs)');

sz= size(fv.x);
fv.x= reshape(fv.x, [prod(sz(1:end-1)), sz(end)]);

for ii = 1:prod(sz(1:end-1))
    [p(ii), h, stats] = ranksum(fv.x(ii, find(fv.y(1, :)))', fv.x(ii, find(fv.y(2, :)))');
    z(ii) = stats.zval;
    x(ii) = (stats.ranksum-(min(sum(fv.y'))*(min(sum(fv.y'))+1)/2))/prod(sum(fv.y'));
end

% SErand = sqrt((0.25 + (sum(sum(fv.y'))-2)*(1/12))./prod(sum(fv.y')));
% z2 = (x-0.5)./SErand;

fv_rval= fv;
fv_rval.x= reshape(x, sz(1:end-1));
fv_rval.z = reshape(z, sz(1:end-1));
fv_rval.p = reshape(p, sz(1:end-1));
fv_rval.sgn_log10_p = reshape(((log(2)+normcdfln(-abs(fv_rval.z(:))))./log(10)), size(fv_rval.z)).*-sign(fv_rval.z);
if isfield(fv, 'className'),
  fv_rval.className= {sprintf('auc( %s , %s )', fv.className{1:2})};
end
fv_rval.y= 1;
fv_rval.yUnit= 'auc';
