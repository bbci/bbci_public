function [divTr, divTe]= sample_KFold(label, folds, varargin)
%SAMPLE_KFOLD - Sampling function: random divisions (by default stratified)
%
%Synopsis:
%  [PARTR, PARTE]= sample_KFold(LABEL, FOLDS, <OPT>)
%
%Arguments:
% LABEL  - class label of size [nClasses x nSamples].
% FOLDS  - DOUBLE nFolds: number of folds into which the samples are
%          divided. Or FOLDS can be [nShifts nFolds] in which case
%          all partitions will also be generated in shifted versions.
% OPT    - property/value list of optinal parameters:
%   'stratified' [BOOL] stratified sampling (true, default)
%          or completely random sampling (false).
%
%Returns:
% DIVTR   - Partitions of the training set
%           DIVTR{n}: cell array holding the training sets folds for
%           shuffle #n, more specificially
%           DIVTR{n}{m} holds the indices of the training set of the m-th
%           fold of shuffle #n
% DIVTE   - analogue to DIVTR, for the test sets

% 2014-02 Martijn Schreuder


props = {'Stratified'      true          'BOOL|DOUBLE[1]'
        };

if nargin==0,
  divTr= props;
  return;
end

opt= opt_proplistToStruct(varargin{:});
[opt,~] = opt_setDefaults(opt, props, 1);

misc_checkType(label, 'DOUBLE[- -]');
misc_checkType(folds, 'DOUBLE|DOUBLE[2]');

nSamples = sum(label,2);

if length(folds)==1
  folds= [1 folds];
end

% check that the number of folds is smaller than the smallest class
if any(folds(2) > nSamples),
    error('The number of folds is larger than the number of samples in the smallest class');
end

%divTr= {cell(1,folds(2))};
%divTe= {cell(1,folds(2))};
for nn= 1:folds(1)
  clear idx;
  % prepare indices
  if opt.Stratified
      for cl = 1:length(nSamples)
          clid = find(label(cl,:));
          idx{cl} = clid(randperm(nSamples(cl)));
      end
  else
      idx{1} = randperm(sum(nSamples));
  end
  
  % make divisions
  for cl = 1:length(idx)
      div{cl}= round(linspace(0, nSamples(cl), folds(2)+1));
  end
      
  % sample
  for kk= 1:folds(2)
    divTe{nn}{kk} = [];
    for cl = 1:length(div),
      divTe{nn}{kk}= sort([divTe{nn}{kk} idx{cl}(div{cl}(kk)+1:div{cl}(kk+1))]);
    end
    divTr{nn}{kk}= setdiff(1:sum(nSamples), divTe{nn}{kk});

    % check that all classes are inhabited
    if ~all(sum(label(:,divTr{nn}{kk}))),
      error('empty classes in training set');
    end
  end
end