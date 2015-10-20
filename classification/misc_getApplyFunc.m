function applyFcn= misc_getApplyFunc(model)
%applyFcn= misc_getApplyFunc(model)


if isstruct(model),
  func= misc_getFuncParam(model.classy);
else
  func= misc_getFuncParam(model);
end

trainFcnName= func2str(func);
if length(trainFcnName)<7 || ~strncmp('train_', trainFcnName, 6),
  error('names of classifier functions need to be prefixed by ''train_''.');
end

baseName= trainFcnName(7:end);
applyFcnName= ['apply_' baseName];
if exist(applyFcnName, 'file'),
  applyFcn= str2func(applyFcnName);
else
  applyFcn= @apply_separatingHyperplane;
end
