function out= apply_separatingHyperplane(C, y)
%APPLY_SEPARATRINGHYPERPLANE - Apply wTx+b classifier to features
%
%Synopsis:
%  OUT= apply_separatingHyperplane(C, X)
%
%Arguments:
%  C   [STRUCT with fields 'w' and 'b'] - Classifier
%  X   [DOUBLE [ndim nsamples]] - Data
%
%Returns:
%  OUT  - Classifier output


out= real( C.w'*y + repmat(C.b, [1 size(y,2)]) );
