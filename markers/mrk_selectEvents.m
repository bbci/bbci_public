function [mrk, ev]= mrk_selectEvents(mrk, ev, varargin)
%MRK_SELECTEVENTS - Select certain events within a marker structure
%
%Synopsis:
%  MRK= mrk_selectEvents(MRK, IDX, <OPT>)
%  MRK= mrk_selectEvents(MRK, 'not', IDX, <OPT>)
%  MRK= mrk_selectEvents(MRK, <'valid', OPT>)
%
%Arguments:
% MRK: STRUCT - Marker structure with obligatory field 'time'.
% IDX: DOUBLE - Indices of events that are to be selected (or discarded, in the
%       second variant with keyword 'not')
% OPT:  PROPLIST - Struct or property/value list of optional properties:
%  'Sort' - BOOL: Evokes a call to mrk_sortChronologically (default 0).
%  'RemoveVoidClasses' - BOOL: Deletes empty classes (default 1), requires
%                 MRK to have a field 'y'.


props= {'Sort',              0  'BOOL'
        'RemoveVoidClasses'  1  'BOOL'};

if nargin==0,
  mrk= props;
  return
end

if nargin>1 && ischar(ev) && strcmpi(ev,'NOT'),
  ev= varargin{1};
  varargin= varargin(2:end);
  invert= 1;
else
  invert= 0;
end

opt= opt_proplistToStruct(varargin{:});
opt= opt_setDefaults(opt, props);
opt_checkProplist(opt, props);

misc_checkType(mrk, 'STRUCT(time)');
misc_checkType(ev, 'CHAR|INT');

if nargin==1 || (ischar(ev) && strcmpi(ev,'VALID')),
  ev= find(any(mrk.y,1));
end

if invert,
  ev= setdiff(1:length(mrk.time), ev);
end

mrk.time= mrk.time(ev);
if isfield(mrk, 'y'),
  mrk.y= mrk.y(:,ev);
end

if isfield(mrk, 'event'),
  for Fld= fieldnames(mrk.event)'
    fld= Fld{1};
    tmp= getfield(mrk.event, fld);
    % the first dimension must be indexed by events
    subidx= repmat({':'}, 1, ndims(tmp));
    subidx{1}= ev;
    mrk.event= setfield(mrk.event, fld, tmp(subidx{:}));
  end
end

if opt.RemoveVoidClasses && isfield(mrk,'y'),
  mrk= mrk_removeVoidClasses(mrk);
end

if opt.Sort,
  mrk= mrk_sortChronologically(mrk, opt);
end
