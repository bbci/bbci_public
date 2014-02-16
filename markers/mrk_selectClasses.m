function [mrk, ev]= mrk_selectClasses(mrk, varargin)
%[mrk, ev]= mrk_selectClasses(mrk, classes, <OPT>)
%[mrk, ev]= mrk_selectClasses(mrk, class1, ..., <OPT>)
%
% this function selects events from a marker structure that belong
% to given classes. a typical application is to select from a multi-class
% experiment a two-class subproblem.
%
% IN   mrk     - marker structure
%      classes - cell array of classes names or
%                vector of class indices
%      classX  - class name or class index
% OPT:  PROPLIST - Struct or property/value list of optional properties:
%  'RemoveVoidClasses' - BOOL: Deletes empty classes (default 1)
%
% OUT  mrk     - structure containing only selected events
%      ev      - indices of select events
%
% EG   mrk_lr= mrk_selectClasses(mrk, {'left', 'right'});
%      mrk_12= mrk_selectClasses(mrk, [1 2]);
%      mrk_lr= mrk_selectClasses(mrk, 'left', 'right');
%
% class names may include the wildcard '*' as first and/or last
% symbol 
% See also procutil_getClassIndices.


props= {'RemoveVoidClasses'  1  '!BOOL'};
props_events= mrk_selectEvents;

if nargin==0,
  mrk= props;
  return
end

if length(varargin)>2 && ischar(varargin{end-1}) && strcmpi(varargin{end-1},'RemoveVoidClasses');
  opt_args=varargin(end-1:end);
  varargin = varargin(1:end-2);
else
  opt_args={};
end  

clInd= procutil_getClassIndices(mrk, varargin{:});

opt= opt_proplistToStruct(opt_args{:});
opt= opt_setDefaults(opt, props);
opt_checkProplist(opt, props);

misc_checkType(mrk, 'STRUCT(className y)');
opt_events = opt_substruct(opt, props_events(:,1));


%% the following is done to keep the order of the specified classes
mrk.y= mrk.y(clInd,:);
mrk.className= mrk.className(clInd);


%% select events belonging to the specified classes ...
ev= find(any(mrk.y, 1));
mrk= mrk_selectEvents(mrk, ev,opt_events);

