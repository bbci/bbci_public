function mrk= mrkutil_appendEventInfo(mrk1, mrk2, varargin)
% MRKUTIL_APPENDEVENTINFO
%
% This functions is used in mrk_mergeMarkers and proc_appendEpochs


misc_checkType(mrk1, 'STRUCT');
misc_checkType(mrk2, 'STRUCT');

if isempty(mrk1),
  mrk= mrk2;
  return;
elseif isempty(mrk2),
  mrk= mrk1;
  return;
end

%% Labels (mrk.y) and class names (mrk.className)
if isfield(mrk1, 'y'),
  s1= size(mrk1.y);
  s2= size(mrk2.y);
  if isfield(mrk1, 'className') && isfield(mrk2, 'className'),
    mrk.y= [mrk1.y, zeros(s1(1), s2(2))];
    mrk2y= [zeros(s2(1), s1(2)), mrk2.y];
    mrk.className= mrk1.className;
    for ii = 1:length(mrk2.className)
      c = find(strcmp(mrk.className,mrk2.className{ii}));
      if isempty(c)
        mrk.y= cat(1, mrk.y, zeros(1,size(mrk.y,2)));
        mrk.className=  cat(2, mrk.className, {mrk2.className{ii}});
        c= size(mrk.y,1);
      elseif length(c)>1,
        error('multiple classes have the same name');
      end
      mrk.y(c,end-size(mrk2.y,2)+1:end)= mrk2.y(ii,:);
    end
  else
    mrk.y= [[mrk1.y; zeros(s2(1), s1(2))], [zeros(s1(1), s2(2)); mrk2.y]];
  end
end
  
%% Merge subfields of mrk.event
if xor(isfield(mrk1,'event'), isfield(mrk2,'event')),
  warning('field ''event'' not found in all markers: lost');
elseif isfield(mrk1,'event'),
  fields1= fieldnames(mrk1.event);
  fields2= fieldnames(mrk2.event);
  lost_fields= setdiff(union(fields1, fields2), intersect(fields1, fields2));
  if ~isempty(lost_fields),
    lost_list= str_vec2str(lost_fields);
    warning('event field(s) {%s} not found in all markers: lost', lost_list{:});
  end
  mrk.event= struct;
  for Fld= intersect(fields1, fields2)',
    fld= Fld{1};
    tmp1= mrk1.event.(fld);
    tmp2= mrk2.event.(fld);
    if xor(iscell(tmp1), iscell(tmp2)),
      error('type mismatch (cell vs array) in field %s', fld);
    end
    % in the variable of mrk.event, the first dimension must index events
    mrk.event= setfield(mrk.event, fld, cat(1, tmp1, tmp2));
  end
end

%% Recursion
if length(varargin)>0,
  mrk= mrkutil_appendEventInfo(mrk, varargin{1}, varargin{2:end});
end
