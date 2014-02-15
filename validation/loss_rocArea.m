function loss= loss_rocArea(label, out, varargin)
%LOSS_ROCAREA - Loss function: Area over the ROC curve
%
%Synopsis:
% LOSS= loss_rocArea(LABEL, OUT)
%
% IN  LABEL - matrix of true class labels, size [nClasses nSamples]
%     OUT   - matrix (or vector for 2-class problems) of classifier outputs
%
% OUT LOSS  - loss value (area over roc curve)
%
%Note: This loss function is for 2-class problems only.

% Benjamin Blankertz


if size(label,1)~=2,
  error('roc works only for 2-class problems');
end
N= sum(label, 2);
lind= [1:size(label,1)]*label;

%resort the samples such that class 2 comes first.
%this makes ties count against the classifier, otherwise
%loss_rocArea(y, ones(size(y))) could result in a loss<1.
[so,si]= sort(-lind);
lind= lind(:,si);
out= out(:,si);

[so,si]= sort(out);
lo= lind(si);
idx2= find(lo==2);
ncl1= cumsum(lo==1);
roc= ncl1(idx2)/N(1);

% area over the roc curve
loss= 1 - sum(roc)/N(2);
