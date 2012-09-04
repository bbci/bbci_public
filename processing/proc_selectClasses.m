function [epo, ev]= proc_selectClasses(epo, varargin)
%PROC_SELECTCLASSES - select only a subset of the avialble classes
%
%Synopsis:
%[epo, ev]= proc_selectClasses(epo, classes)
%[epo, ev]= proc_selectClasses(epo, class1, ...)
%
% IN   epo     - epoched data structure
%      classes - cell array of classes names or
%                vector of class indices
%      classX  - class name or class index. in the first place also
%                'not' can be used to invert the selection.
%
% OUT  epo     - epoch structure containing only selected events
%      ev      - indices of select events
%
% this function selects events from a epoch structure that belong
% to given classes. a typical application is to select from a multi-class
% experiment a two-class subproblem.
% class names may include the wildcard '*' as first exclusive-or last
% symbol, see procutil_getClassIndices.
%
% Examples
%      epo_lr= mrk_selectClasses(epo, {'left', 'right'});
%      epo_12= mrk_selectClasses(epo, [1 2]);
%      epo_lr= mrk_selectClasses(epo, 'left', 'right');
%      epo_nl= mrk_selectClasses(epo, 'not', 'left*');
%

% Benjamin Blankertz
epo = misc_history(epo);

misc_checkType(epo, 'STRUCT(className y)');

clInd= procutil_getClassIndices(epo, varargin{:});
ev= find(any(epo.y(clInd,:)==1,1));

%% the following is done to keep the order of classes as specified
epo.y= epo.y(clInd,:);
epo.className= epo.className(clInd);

%% the following is to avaid an error in proc_selectEpochs
if length(ev)==size(epo.y,2)
  return;
end

epo= proc_selectEpochs(epo, ev);
