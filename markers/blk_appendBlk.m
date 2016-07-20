function blk= blk_appendBlk(blk1, blk2, Tmsec)
%BLK_APPENDBLK - Append (timewise) two block structures
%
%Synopsis:
%  BLK= blk_appendBlk(BLK1, BLK2, TMSEC)
%  BLK= blk_appendBlk(BLK1, BLK2, CNT)
%
%Arguments:
%  BLK1, BLK2: block structures (or empty []), see blk_segmentsFromMarkers
%  TMSEC:      duration of first data set in msec
%  CNT:        struct (like cnt) with fields T (duration of first data set
%              in samples) and fs (sampling rate).
%
%Returns:
%  blk:        block structure


misc_checkType(blk1, 'STRUCT(ival)');
misc_checkType(blk2, 'STRUCT(ival)');
misc_checkType(Tmsec', '!DOUBLE[1]|struct(T fs)');

if isempty(blk1),
  blk= blk2;
  return;
end

if isstruct(Tmsec),
  cnt= Tmsec;
  Tmsec= sum(cnt.T)*1000/cnt.fs;
end

blk2.ival= blk2.ival + Tmsec;
if isempty(blk1),
  blk= blk2;
  return;
end

% Add ID (counter) for datasets, or check consistency if such ID are given
if ~isfield(blk1, 'event') || ~isfield(blk1.event, 'dataset'),
  blk1.event.dataset= ones([size(blk1.ival,1) 1]);
end
last_dataset= max(blk1.event.dataset);
if isfield(blk2, 'event') && isfield(blk2.event, 'dataset'),
  if any(blk2.event.dataset) <= last_dataset,
    warning('second blk contains small dataset ID than first blk');
  end
else
  blk2.event.dataset= (last_dataset + 1) * ones([size(blk2.ival,1) 1]);
end

blk= blk_mergeBlk(blk1, blk2);
