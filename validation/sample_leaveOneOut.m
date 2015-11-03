function [divTr, divTe]= sample_leaveOneOut(label, trainSize)
%SAMPLE_LEAVEONEONE - Sampling function: leave-one-out
%
%Synopsis:
% [PARTR, PARTE]= sample_leaveOneOut(LABEL, TRAINSIZE)
%
% IN  LABEL   - class labels, but here only the length of the 2nd dim is
%               used (to determine the number of samples)
%     TRAINSIZE - number of samples to be selected for doing the loo.
% 
% OUT PARTR   - Partitions of the training set
%               PARTR{n}: cell array holding the training sets
%               folds for shuffle #n, more specificially
%               PARTR{n}{m} holds the indices of the training set of
%               the m-th fold of shuffle #n.
%     PARTE   - analogue to PARTR, for the test sets

% Benjamin Blankertz

misc_checkType(label, 'DOUBLE[- -]');
misc_checkTypeIfExists('trainSize', 'DOUBLE');

nSamples= size(label,2);
if nargin<2,
  trainSize= nSamples-1;
end

divTr= cell(1, 1);
divTe= cell(1, 1);
for nn= 1:nSamples,
  divTe{1}(nn)= {nn};
  idx= randperm(nSamples);
  idx(idx==nn)= [];
  divTr{1}(nn)= {idx(1:trainSize)};
end
