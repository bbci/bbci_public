function range= visutil_commonRangeForGA(erp, varargin)

props= {'CLabERP'         '*'    'CELL{CHAR}|CHAR';
        'IvalERP'         []     'DOUBLE[2]';
        'SymERP'          0      'BOOL';
        'NiceRangeERP'    0      'DOUBLE';
        'EnlageRangeERP'  0.02   'DOUBLE';
        'CLabScalp'       '*'    'CELL{CHAR}|CHAR';
        'IvalScalp'       []     'DOUBLE';
        'SymScalp'        1      'BOOL'
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
