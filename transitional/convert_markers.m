function mrk= convert_markers(mrk_old)

mrk= rmfield(mrk_old, {'pos','toe','fs'});

if isfield(mrk, 'indexedByEpochs'),
  mrk= rmfield(mrk, mrk.indexedByEpochs);
  mrk.event= struct;
  for Fld= mrk.indexedByEpochs,
    fld= Fld{1};
    mrk.event= setfield(mrk.event, fld, mrk_old.(fld));
  end
end

mrk.time= mrk_old.pos/mrk_old.fs*1000;
mrk.desc= mrk_old.toe;
