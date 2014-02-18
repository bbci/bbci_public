function opt= opt_overwriteVoids(opt, fld, default_value);

if ~isfield(opt, fld),
  return;
end

for k= 1:length(opt),
  if isempty(opt(k).(fld)),
    opt(k).(fld)= default_value;
  end
end
