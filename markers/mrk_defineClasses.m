function mrk= mrk_defineClasses(mk, classDef, varargin)
%MRK_DEFINECLASSES - Convert BV Markers to class defining marker structure
%
%Synopsis:
% MRK_OUT= mrk_defineClasses(MRK_IN, CLASS_DEF, <OPT>)
%
%Arguments:
% MRK_IN: Marker structure as received by file_readBVmarkers.
%  MarkerFormat can be numeric or string.
% CLASS_DEF: Class array of size {2 x nClasses}. The first row
%  specifies the markers of each class, each cell being either
%  a cell array of strings (for MarkerFormat='string') or a vector
%  of integers (for MarkerFormat='numeric').
%  The second row specifies the class names, each cell begin a string.
%  (If the second row does not exist, generic class names are defined.)
% OPT: struct or property/value list of optional properties:
%  'RemoveVoidClasses': Void classes are removed from the list of classes,
%     default 0.
%  'KeepAllMarkers': Keep also for markers, which do not belong to any
%     of the specified classes, default 0.
%
%Returns:
% MRK_OUT: Marker structure with classes defined by labels
%     (fields 'y' and 'className')
%
%Example:
% file= 'Gabriel_01_07_24/selfpaced1sGabriel';
% [cnt,mk]= file_readBV(file);
% classDef= {[65 70], [74 192]; 'left','right'};
% mrk= mrk_defineClasses(mk, classDef);
%
% [cnt,mk]= file_readBV(file, 'MarkerFormat','string');
% classDef= {{'S 65','S 70'},{'S 74', 'S192'}; 'left','right'}
% mrk= mrk_defineClasses(mk, classDef);
% %% does the same


props= {'KeepAllMarkers'     0  'BOOL'
        'RemoveVoidClasses'  0  'BOOL'};
props_selectEvents= mrk_selectEvents;

if nargin==0,
  mrk= opt_catProps(props, props_selectEvents); 
  return
end

opt= opt_proplistToStruct(varargin{:});
opt= opt_setDefaults(opt, props);
opt_checkProplist(opt, props);

misc_checkType(mk, 'STRUCT(time event)');
misc_checkType(mk.event, 'STRUCT(desc)', 'mk.event');
misc_checkType(classDef, 'CELL');

nClasses= size(classDef,2);
if iscell(mk.event.desc),
  mrk= struct('time', mk.time, 'event',struct('desc',{mk.event.desc}));
else
  mrk= struct('time', mk.time, 'event',struct('desc',mk.event.desc));
end

mrk.y= zeros(nClasses, numel(mrk.time));
for cc= 1:nClasses,
  if isnumeric(classDef{1,cc}),
    % vector as in {[10 11], [20:26];  'target', 'nontarget'}
    mrk.y(cc,:)= ismember(mk.event.desc, classDef{1,cc});
  elseif iscell(classDef{1,cc}),
    % cell of strings as in {{'S 10','S 11'}, {'S 20','S 21'};
    %                        'target',        'nontarget'}
    mrk.y(cc,:)= ismember(mk.event.desc, classDef{1,cc});
  else
    % single string as in {'S10', 'S20';  'target', 'nontarget'}
    mrk.y(cc,:)= ismember(mk.event.desc, classDef(1,cc));
  end
end

if size(classDef,1)>1,
  mrk.className= classDef(2,:);
else
  mrk.className= str_cprintf('class %d', 1:nClasses);
end

if ~opt.KeepAllMarkers,
  opt_selectEvents= opt_substruct(opt, props_selectEvents(:,1));
  mrk= mrk_selectEvents(mrk, 'valid', opt_selectEvents);
end
if opt.RemoveVoidClasses,
  mrk= mrk_removeVoidClasses(mrk);
end
