function mrk= mrkutil_appendEventInfo(mrk1, mrk2)
% MRKUTIL_APPENDEVENTINFO
%
% This functions is used in mrk_mergeMarkers and proc_appendEpochs


misc_checkType(mrk1, 'STRUCT');
misc_checkType(mrk2, 'STRUCT');

%% Merge subfields of mrk.event
if xor(isfield(mrk1,'event'), isfield(mrk2,'event')),
  warning('field ''event'' not found in all markers: lost');
  mrk= mrk1;
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
else
    mrk = mrk1;
end
