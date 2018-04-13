function mrk= mrk_appendMarkers(mrk1, mrk2, Tmsec)
%MRK_APPENDMARKERS - Append (timewise) two marker structures
%
%Synopsis:
%  MRK= mrk_appendMarkers(MRK1, MRK2, TMSEC)
%  MRK= mrk_appendMarkers(MRK1, MRK2, CNT)
%
%Arguments:
%  MRK1, MRK2: marker structures (or empty [])
%  TMSEC:      duration of first data set in msec
%  CNT:        struct (like cnt) with fields T (duration of first data set
%              in samples) and fs (sampling rate).
%
%Returns:
%  mrk:        marker structure


misc_checkType(mrk1, 'STRUCT(time)');
misc_checkType(mrk2, 'STRUCT(time)');
misc_checkType(Tmsec, '!DOUBLE[1]|struct(T fs)');

if isempty(mrk1),
  mrk= mrk2;
  return;
end

if isstruct(Tmsec),
  cnt= Tmsec;
  Tmsec= sum(cnt.T)*1000/cnt.fs;
end

mrk2.time= mrk2.time + Tmsec;
if isempty(mrk1),
  mrk= mrk2;
  return;
end

if isfield(mrk1, 'event') && isfield(mrk1.event, 'blkno') && ...
    isfield(mrk2, 'event') && isfield(mrk2.event, 'blkno'),
  offset= max(mrk1.event.blkno) - min(mrk2.event.blkno) + 1;
  mrk2.event.blkno= mrk2.event.blkno + offset;
end

mrk= mrk_mergeMarkers(mrk1, mrk2);
