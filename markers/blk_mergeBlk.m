function blk= blk_mergeBlk(blk1, blk2, varargin)
%BLK_MERGEBLK - Merge Block Structures
%
%Description:
% This function merges two or more marker structs into one.
%
%Synopsis:
% BLK= blk_mergeMarkers(BLK1, BLK2, ...)
%
%Arguments:
%  BLK1, ...: block structures, see blk_segmentsFromMarkers, (or empty [])
%
%Returns:
%  BLK:       block structure

misc_checkType(blk1, 'STRUCT(ival)');
misc_checkType(blk2, 'STRUCT(ival)');


if isempty(blk1),
  blk= blk2;
  return;
elseif isempty(blk2),
  blk= blk1;
  return;
end

blk= mrkutil_appendEventInfo(blk1, blk2);
blk.ival= cat(1, blk1.ival, blk2.ival);

%% Labels (blk.y) and class names (blk.className)
if xor(isfield(blk1, 'y'), isfield(blk2, 'y')),
  error('either none or both marker structres must have field ''y''.');
end 
if isfield(blk1, 'y'),
  s1= size(blk1.y);
  s2= size(blk2.y);
  if isfield(blk1, 'className') && isfield(blk2, 'className'),
    blk.y= [blk1.y, zeros(s1(1), s2(2))];
    blk2y= [zeros(s2(1), s1(2)), blk2.y];
    blk.className= blk1.className;
    for ii = 1:length(blk2.className)
      c = find(strcmp(blk.className,blk2.className{ii}));
      if isempty(c)
        blk.y= cat(1, blk.y, zeros(1,size(blk.y,2)));
        blk.className=  cat(2, blk.className, {blk2.className{ii}});
        c= size(blk.y,1);
      elseif length(c)>1,
        error('multiple classes have the same name');
      end
      blk.y(c,end-size(blk2.y,2)+1:end)= blk2.y(ii,:);
    end
  else
    blk.y= [[blk1.y; zeros(s2(1), s1(2))], [zeros(s1(1), s2(2)); blk2.y]];
  end
end

%% Recursion
if length(varargin)>0,
  blk= blk_mergeMarkers(blk, varargin{1}, varargin{2:end});
end
