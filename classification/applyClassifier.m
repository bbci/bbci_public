function out= applyClassifier(fv, C, idx)
%APPLYCLASSIFIER - Apply a classifier to a set of features
%
%Synopsis:
%  OUT= applyClassifier(FV, C, <IDX>)
%
%Arguments:
%  FV   - struct of feature vectors
%  C    - struct of trained classifier, out of trainClassifier
%  IDX  - array of indices (of features vectors) to which the classifier
%         is applied
%
%Returns:
%  OUT  - array of classifier outputs

misc_checkType(fv, 'STRUCT(x y)');
misc_checkType(fv.x, 'DOUBLE[- -]|DOUBLE[- - -]|DOUBLE[- - - -]', 'fv.x');
misc_checkType(C, 'STRUCT');
misc_checkTypeIfExists('idx', 'DOUBLE[-]');

fv= proc_flaten(fv);
if ~isfield(C, 'applyFcn'),
  C.applyFcn= @apply_separatingHyperplane;
end

if ~exist('idx','var'), 
  out= C.applyFcn(C, fv.x);
else
  out= C.applyFcn(C, fv.x(:,idx));
end
