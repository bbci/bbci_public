function out= applyClassifier(fv, model, C, idx)
%out= applyClassifier(fv, classy, C, <idx>)


fv= proc_flaten(fv);

if ~exist('idx','var'), 
  out= C.applyFcn(C, fv.x);
else
  out= C.applyFcn(C, fv.x(:,idx));
end
