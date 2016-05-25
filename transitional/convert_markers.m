function mrk= convert_markers(mrk_old)

mrk= rmfield(mrk_old, {'pos','fs'});

mrk.time= mrk_old.pos*1000/mrk_old.fs;
mrk.event= struct;
if isfield(mrk_old, 'toe'),
  mrk.event.desc= mrk_old.toe(:);
  mrk= rmfield(mrk, {'toe'});
end

if isfield(mrk, 'indexedByEpochs'),
  mrk= rmfield(mrk, setdiff(mrk.indexedByEpochs, 'time'));
  mrk= rmfield(mrk, 'indexedByEpochs');
  nEvents= length(mrk.time);
  for Fld= mrk_old.indexedByEpochs,
    fld= Fld{1};
    fieldvar= mrk_old.(fld);
    sz= size(fieldvar);
    eventdim= find(sz==nEvents);
    if isempty(eventdim),
      error('no event information found in field %s', fld);
    end
    if length(eventdim)>1,
      error('cannot decide event dimension in field %s', fld);
    end
    if eventdim~=1,
      % permute dimensions to make the first one index events
      dimorder= [eventdim setdiff(1:length(sz), eventdim)];
      fieldvar= permute(fieldvar, dimorder);
    end
    mrk.event= setfield(mrk.event, fld, fieldvar);
  end
end
