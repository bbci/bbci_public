function [epo, ev]= proc_selectClasses(epo, cls, varargin)
%PROC_SELECTCLASSES - select only a subset of the avialble classes
%
%Synopsis:
%[epo, ev]= proc_selectClasses(epo, classes)
%
% IN   epo     - epoched data structure
%      classes - cell array of classes names or vector of class indices
%
% OUT  epo     - epoch structure containing only selected events
%      ev      - indices of select events
%
%Description:
% This function selects events from a epoch structure that belong
% to given classes. a typical application is to select from a multi-class
% experiment a two-class subproblem.
% Class names may include regular expressions, see regexpi. This also
% implies that you might have to escape some characters, see last example.
%
% Examples
%      epo_lr= proc_selectClasses(epo, {'left', 'right'});
%      epo_12= proc_selectClasses(epo, [1 2]);
%      epo_nl= proc_selectClasses(epo, {'not', 'left*'});
%
%      epo= proc_selectClasses(epo, 'r\^2 \( a , b \)';

% Benjamin Blankertz


props_selectEvents= proc_selectEpochs;

if nargin==0,
  epo= props_selectEvents; return
end

misc_checkType(epo, 'STRUCT(className y)');
epo= misc_history(epo);

opt= opt_proplistToStruct(varargin{:});

clInd= procutil_getClassIndices(epo, cls);
ev= find(any(epo.y(clInd,:)==1,1));

%% the following is done to keep the order of classes as specified
epo.y= epo.y(clInd,:);
epo.className= epo.className(clInd);

%% the following is to avoid an error in proc_selectEpochs
if length(ev)==size(epo.y,2)
  return;
end

epo= proc_selectEpochs(epo, ev, opt);
