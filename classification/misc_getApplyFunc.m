function applyFcn= misc_getApplyFunc(model)
%applyFcn= misc_getApplyFunc(model)


if isstruct(model),
  func= misc_getFuncParam(model.classy);
else
  func= misc_getFuncParam(model);
end

applyFcnName= ['apply_' func2str(func)];
if exist(applyFcnName, 'file'),
  applyFcn= str2func(applyFcnName);
else
  applyFcn= @apply_separatingHyperplane;
end
