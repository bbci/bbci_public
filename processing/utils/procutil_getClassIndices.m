function clInd= procutil_getClassIndices(className, varargin)
%clInd= getClassIndices(className, classes)
%clInd= getClassIndices(className, class1, ...)
%
% this function returns in indices of classes relativ to a
% cell array of class names.
%
% IN   className - cell array of class names, or
%                  a structure containing such a field (as mrk, epo)
%      classes   - cell array of classes names or
%                  vector of class indices
%      classX    - class name or class index. in this format you can
%                  also use 'not' in the first place to invert the
%                  selection.
%
% OUT  clInd     - class indices
%
% Class names may include regular expressions, see regexpi. This also
% implies that you might have to escape some characters, such as '^',
% '(' and ')'.
% This function is used, e.g., in mrk_selectClasses, mrk_mergeClasses

if nargin==0,
  clInd=[];
  return
end

misc_checkType(className, '!STRUCT|!CELL{CHAR}');


if isempty(varargin),
  warning('no classes specified');
  return;
end
if isstruct(className),
  className= className.className;
end

invert= 0;
if ischar(varargin{1}),
%% each class specified as one input argument (string)
  if strcmp(varargin{1},'not'),
    invert= 1;
    classes= {varargin{2:end}};
  else
    classes= {varargin{:}};
  end
else
%% classes specified as entries (string) in a cell array or
%% classes specified as indices in a vector
  if nargin>2,
    error('wrong usage: only one cell array / vector may be specified');
  end
  classes= varargin{1};
end

if ~iscell(classes),
%% class indices given in a vector
  clInd= classes;
else
%% class names given
  clInd= [];
  for desiredClass= classes,
    clInd= [clInd, str_patternMatch(desiredClass{:},className)];
  end
end

if invert,
  clInd= setdiff(1:length(className), clInd,'legacy');
end
