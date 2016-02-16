function [C,params]= trainClassifier(fv, classy, idx)
%TRAINCLASSIFIER - Train a classifier model on a given set of features
%
%Description:
%  This function is a wrapper for the specific train_* functions.
%
%Synopsis:
%  C= trainClassifier(FV, CLASSIFIER, <IDX>)
%
%Arguments:
%  FV     - struct of feature vectors
%  CLASSY - Specification of the classifier. It can either simply be a
%           function handle, or a CELL {@FCN, PARAM1, PARAM2, ...}.
%  IDX    - array of indices (of features vectors) to which the classifier
%           is applied
%
%Returns:
%  C    - struct of trained classifier, to be used in applyClassifier

misc_checkType(fv, 'STRUCT(x y)');
misc_checkType(fv.x, 'DOUBLE[- -]|DOUBLE[- - -]|DOUBLE[- - - -]', 'fv.x');
misc_checkType(classy, 'FUNC|CELL');
misc_checkTypeIfExists('idx', 'DOUBLE[-]');

fv= proc_flaten(fv);
if nargin > 2,
  fv.x= fv.x(:,idx);
  fv.y= fv.y(:,idx);
end

if isstruct(classy),
%% classifier is given as model with free model parameters
  error('classifiers with free parameters are not implemented yet');
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
