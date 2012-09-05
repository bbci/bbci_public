function s= struct_createfields(s, flds, varargin)

props = {
         'Matchsize'	[];
         'Value'        NaN
         };

if nargin==0
    s=props;return
end
     
opt= opt_proplistToStruct(varargin{:});
[opt, isdefault]= opt_setDefaults(opt, props);
opt_checkProplist(opt, props);
misc_checkType(s,'STRUCT');
misc_checkType(flds,'CHAR|CELL{CHAR}');


if ischar(flds),
  flds= {flds};
end

for ii= 1:length(flds),
  if isempty(opt.matchsize),
    val= opt.value;
  else
    val= repmat(opt.value, size(opt.matchsize.(flds{ii})));
  end
  [s.(flds{ii})]= deal(val);
end
