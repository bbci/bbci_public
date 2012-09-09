function classifier= bbci_apply_evalClassifier(fv, bbci_classifier)
%BBCI_APPLY_EVALCLASSIFIER - Apply classifier to feature vector
%
%Synopsis:
%  CLASSIFIER= bbci_apply_evalClassifier(FV, BBCI_CLASSIFIER)

% 02-2011 Benjamin Blankertz


classifier.x= bbci_classifier.fcn(bbci_classifier.C, fv);
classifier.x= classifier.x(:);
