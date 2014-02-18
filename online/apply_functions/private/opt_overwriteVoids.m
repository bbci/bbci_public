function opt= opt_overwriteVoids(opt, fld, props);

if ~isfield(opt, fld),
  return;
end

default= opt_propspecToStruct(props);
for k= 1:length(opt),
  if isempty(opt(k).(fld)),
    opt(k).(fld)= default.(fld);
  end
end
