function mrk= mrk_sortChronologically(mrk, varargin)
%MRK_SORTCHRONOLOGICALLY - Sort Markers Chronologically
%
%Synopsis:
%  MRK_OUT= mrk_sortChronologically(MRK_IN, <OPT>)
%
%Arguments:
%  MRK_IN: Marker structure as received by file_loadBV
%  OPT: struct or property/value list of optional properties:
%    'RemoveVoidClasses': Void classes are removed from the list of classes.
%    'Classwise': Each class is sorted chronologically, default 0.
%
%Returns:
% MRK_OUT: Marker structure with events sorted chronologically

% Benjamin Blankertz


props= {'Sort',              0  'BOOL';
        'RemoveVoidClasses'  1  'BOOL';
        'Classwise'          0  '!BOOL';
        };
props_selectEvents= mrk_selectEvents;

if nargin==0,
  mrk= opt_catProps(props, props_selectEvents);
  return
end

opt= opt_proplistToStruct(varargin{:});
opt= opt_setDefaults(opt, props);
opt_checkProplist(opt, props, props_selectEvents);

misc_checkType(mrk, 'STRUCT(time)');

if opt.Classwise,
  nClasses= size(mrk.y,1);
  si= zeros(nClasses, length(mrk.time));
  for ci= 1:nClasses,
    idx= find(mrk.y(ci,:));
    [so,sidx]= sort(mrk.time(idx));
    si(ci, 1:length(idx))= idx(sidx);
  end
  si= si(find(si));
else
  [so,si]= sort(mrk.time);
end

opt_selectEvents= opt_substruct(opt, props_selectEvents(:,1));
mrk= mrk_selectEvents(mrk, si, opt_selectEvents, 'Sort',0);
