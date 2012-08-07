function mrk= mrk_defineClasses(mk, classDef, varargin)
%MRK_DEFINECLASSES - Convert BV Markers to class defining marker structure
%
%Synopsis:
% MRK_OUT= mrk_defineClasses(MRK_IN, CLASS_DEF, <OPT>)
%
%Arguments:
% MRK_IN: Marker structure as received by eegfile_loadBV
% CLASS_DEF: Class array of size {2 x nClasses}. The first row
%  specifies the markers of each class, each cell being either
%  a cell array of strings or a vector of integers. The second
%  row specifies the class names, each cell begin a string.
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
% [cnt,mk]= eegfile_loadBV('Gabriel_01_07_24/selfpaced1sGabriel');
% classDef= {[65 70], [74 192]; 'left','right'};
% mrk= mrk_defineClasses(mk, classDef);
%
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

misc_checkType('mk', 'STRUCT(time)');
misc_checkType('classDef', 'CELL');

%iS= ~apply_cellwise2(regexp(mk.type, 'Stimulus'),'isempty');
%iR= ~apply_cellwise2(regexp(mk.type, 'Response'),'isempty');
iS= ~cellfun(@isempty, regexp(mk.type, 'Stimulus'));
iR= ~cellfun(@isempty, regexp(mk.type, 'Response'));
valid= find(iS|iR);
sgn= iS-iR;
mrk.time= mk.time(valid);
mrk_desc= cellfun(@(x)(str2double(x(2:end))), mk.desc(valid));
mrk.desc= sgn(valid) .* mrk_desc;

nClasses= size(classDef,2);
nEvents= length(valid);
mrk.y= zeros(nClasses, nEvents);
for cc= 1:nClasses,
  if isnumeric(classDef{1,cc}),
    mrk.y(cc,:)= ismember(mrk.desc, classDef{1,cc});
  elseif iscell(classDef{1,cc}),
    mrk.y(cc,:)= ismember(mk.desc(valid), classDef{1,cc});
  else
    mrk.y(cc,:)= ismember(mk.desc(valid), classDef(1,cc));
  end
end

if size(classDef,1)>1,
  mrk.className= classDef(2,:);
end

if ~opt.KeepAllMarkers,
  opt_selectEvents= opt_substruct(opt, props_selectEvents(:,1));
  mrk= mrk_selectEvents(mrk, 'valid', opt_selectEvents);
end
if opt.RemoveVoidClasses,
  mrk= mrk_removeVoidClasses(mrk);
end
