function [divTr, divTe]= sample_chronKfold(label, folds)
%SAMPLE_CHRONKFOLD - Sampling function: chronological consequtive folds
%
%Synopsis:
%  [PARTR, PARTE]= sample_chronKfold(LABEL, FOLDS)
%
% IN  LABEL   - class labels, but here only the length of the 2nd dim is
%               used (to determine the number of samples)
%     FOLDS   - DOUBLE nFolds: number of folds into which the samples are
%               divided. Or FOLDS can be [nShifts nFolds] in which case
%               all partitions will also be generated in shifted versions.
% 
% OUT PARTR   - Partitions of the training set
%               PARTR{n}: cell array holding the training sets
%               folds for shuffle #n, more specificially
%               PARTR{n}{m} holds the indices of the training set of
%               the m-th fold of shuffle #n.
%     PARTE   - analogue to PARTR, for the test sets

% Benjamin Blankertz

misc_checkType(label, 'DOUBLE[- -]');
misc_checkType(folds, 'DOUBLE|DOUBLE[2]');

nSamples= size(label,2);

if length(folds)==1
  folds= [1 folds];
end

divTr= {cell(1,folds(2))};
divTe= {cell(1,folds(2))};
for nn= 1:folds(1)
  div= round(linspace(0+(nn-1), nSamples-(folds(1)-nn), folds(2)+1));
  for kk= 1:folds(2)
    divTe{nn}{kk}= div(kk)+1:div(kk+1);
    divTr{nn}{kk}= setdiff(nn:nSamples-(folds(1)-nn), divTe{nn}{kk});
    % check that all classes are inhabited
    if ~all(sum(label(:,divTr{nn}{kk}))),
      error('empty classes in training set');
    end
  end
end
