function range= visutil_commonRangeForGA(erp, varargin)
%VISUTIL_COMMONRANGEFORGA - Determine plotting range for grand average ERPs
%
%Synposis:
% RANGE= visutil_commonRangeForGA(ERP, <OPT>)
%
%Input:
% ERP: cell of size [N x C] containing ERPs of N subjects and C conditions,
%      plotting ranges are determined for each condition separately
% OPT: struct or property/value list of optional properties:
%  .CLabERP, CLabScalp - channels to be considered for ERP/scalp plots,
%                        default: '*' (all channels)
%  .IvalERP, IvalScalp - interval for ERP/scalp plots to be considered,
%                        default: [] (whole ERP)
%  .SymERP, SymScalp   - make ERP/scalp range symmetric,
%                        default: false/true
%
%Output:
% RANGE: struct containing the two fields:
%  .erp   - plotting range for single channel ERPs
%  .scalp - plotting range for scalp maps

props= {'CLabERP'         '*'    'CELL{CHAR}|CHAR';
        'CLabScalp'       '*'    'CELL{CHAR}|CHAR';
        'IvalERP'         []     'DOUBLE[2]';
        'IvalScalp'       []     'DOUBLE';
        'SymERP'          0      'BOOL';
        'SymScalp'        1      'BOOL'
        'NiceRangeERP'    0      'DOUBLE';
        'EnlageRangeERP'  0.02   'DOUBLE';
       };

if nargin==0,
  range= props; return
end

misc_checkType(erp, 'CELL{STRUCT(x fs clab)}');
opt= opt_proplistToStruct(varargin{:});
[opt, isdefault]= opt_setDefaults(opt, props);
opt_checkProplist(opt, props);

if opt.NiceRangeERP && isdefault.EnlageRangeERP,
  opt.EnlageRangeERP= 0;
end

range.erp= [inf -inf];
if ~isempty(opt.IvalScalp),
  range.scalp= [inf -inf];
end

for ff= 1:size(erp,2),
  erp_ga= proc_grandAverage(erp{:,ff});
  
  tmp= proc_selectChannels(erp_ga, opt.CLabERP);
  if ~isempty(opt.IvalERP),
    tmp= proc_selectIval(tmp, opt.IvalERP);
  end
  range.erp(1)= min(range.erp(1), min(tmp.x(:))); 
  range.erp(2)= max(range.erp(2), max(tmp.x(:))); 
  
  if ~isempty(opt.IvalScalp),
    tmp= proc_jumpingMeans(erp_ga, opt.IvalScalp);
    tmp= proc_selectChannels(tmp, opt.CLabScalp);
    range.scalp(1)= min(range.scalp(1), min(tmp.x(:))); 
    range.scalp(2)= max(range.scalp(2), max(tmp.x(:))); 
  end

end

if opt.SymERP,
  range.erp= [-1 1]*max(abs(range.erp));
end
if opt.EnlageRangeERP>0,
  range.erp= range.erp + [-1 1]*opt.EnlageRangeERP*diff(range.erp);
end
if opt.NiceRangeERP>0,
  res= opt.NiceRangeERP;
  range.erp(1)= floor(res*range.erp(1))/res;
  range.erp(2)= ceil(res*range.erp(2))/res;
end
if ~isempty(opt.IvalScalp) && opt.SymScalp,
  range.scalp= [-1 1]*max(abs(range.scalp));
end
