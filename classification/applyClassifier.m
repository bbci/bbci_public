function out= applyClassifier(fv, model, C, idx)
%out= applyClassifier(fv, classy, C, <idx>)


fv= proc_flaten(fv);
if ~isfield(C, 'applyFcn'),
  C.applyFcn= @apply_separatingHyperplane;
end

if ~exist('idx','var'), 
  out= C.applyFcn(C, fv.x);
else
  out= C.applyFcn(C, fv.x(:,idx));
end
