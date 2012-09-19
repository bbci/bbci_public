function [C,params]= trainClassifier(fv, classy, idx)
%C= trainClassifier(fv, classy, <idx>)

fv= proc_flaten(fv);
if exist('idx', 'var'), 
  fv.x= fv.x(:,idx);
  fv.y= fv.y(:,idx);
end

if isstruct(classy),
%% classifier is given as model with free model parameters
  model= classy;
  classy= select_model(fv, model);
end

[func, params]= misc_getFuncParam(classy);
if isfield(fv,'classifier_param')
  C= func(fv.x, fv.y, fv.classifier_param{:}, params{:});
else
  C= func(fv.x, fv.y, params{:});
end
C.applyFcn= misc_getApplyFunc(classy);
