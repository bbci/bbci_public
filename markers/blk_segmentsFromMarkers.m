function blk = blk_segmentsFromMarkersNew(mrk, varargin)
%BLK_SEGMENTSFROMMARKERS - Define segments based on markers
%
% Synopsis:
%   BLK = blk_segmentsFromMarkers(MRK, <OPT>)
%
% Input:
%   MRK - BV marker structure (struct of arrays) such as return by
%         file_readBVmarkers(..., 0) or
%   FILENAME -  (in this case markers are loaded from that file)
%
%   OPT - struct or property/value list of optional fields/properties:
%    StartMarker: Default: {'New Segment'}
%    EndMarker: If end_marker is empty, each segments ends with the
%       beginning of the next one. Default [].
%    ExcludeStartMarker: Start marker of intervals that should be excluded
%    ExcludeEndMarker: End marker of intervals that should be excluded
%    StartFirstBlock: Default: false
%    SkipUnfinished:  Default: true
%
% Output:
%   BLK - an Nx2 array with each row defining a segment in time ('block')
%
% See also:
%   mrk_evenlyInBlocks

% Benjamin Blankertz Oct 2007
% 6-2015 Adapted to new Toolbox (Laura A, Markus W.)


opt= opt_proplistToStruct(varargin{:});

props={'StartMarker'       {'New Segment',''} 'CHAR|CELL{CHAR}'
       'EndMarker'             ''             'CHAR|CELL{CHAR}'
       'ExcludeStartMarker'    ''             'CHAR|CELL{CHAR}'
       'ExcludeEndMarker'      ''             'CHAR|CELL{CHAR}'
       'StartFirstBlock'       0              'BOOL'
       'SkipUnfinished'        1              'BOOL'};

if nargin==0,
  blk= props; 
  return
end

opt= opt_proplistToStruct(varargin{:});
opt= opt_setDefaults(opt, props);
opt_checkProplist(opt, props);

misc_checkType(mrk, 'STRUCT(time event)');
misc_checkType(mrk.event, 'STRUCT(desc)', 'mrk.event');

classDef= {opt.StartMarker, ...
           opt.EndMarker, ...
           opt.ExcludeStartMarker, ...
           opt.ExcludeEndMarker};

if isfield(mrk.event, 'desc'),
  mrk= mrk_defineClasses(mrk, classDef, 'RemoveVoidClasses',0); %maybecomment
else
  mkk= mrk;
  mkk.className= {'start','end','start of pause','end of pause'};
  mkk.y= zeros(length(classDef), size(mkk.y,2));
  for cc= 1:length(classDef),
    ci= strmatch(classDef{cc}, mrk.className, 'exact');
    if ~isempty(ci),
      mkk.y(cc,:)= mrk.y(ci,:);
    end
  end
  mrk= mrk_selectEvents(mkk, 'valid', 'RemoveVoidClasses',0);
end

blk = [];
if opt.StartFirstBlock>0,
  if ~mrk.y(1,1),
    %% first marker is non a start marker: start block at the beginning
    status= 1;
    mrk_start= opt.StartFirstBlock;
    warning('missing start marker: starting first block as specified');
  end
else
  status = 0;
end

for i = 1:size(mrk.y,2);
  switch status
   case 0   % no session started, wait for marker 1
    if mrk.y(1,i),
      if isempty(opt.EndMarker),  %% do not expect end marker
        if ~isnan(mrk_start),
          blk = cat(1, blk, [mrk_start,mrk.time(i)]);
        end
      else
        status = 1;
      end
      mrk_start = mrk.time(i);
    end
   case 1   % session started, no pause, wait for end or pause start
    if mrk.y(2,i)
      blk = cat(1,blk,[mrk_start,mrk.time(i)]);
      status = 0;
    end
    if mrk.y(3,i)
      blk = cat(1,blk,[mrk_start,mrk.time(i)]);
      status = 2;
    end
   case 2   %paused wait for pause end
    if mrk.y(4,i)
      mrk_start = mrk.time(i);
      status = 1;
    end
    if mrk.y(2,i)
      status = 0;
    end
  end
end

if status==1,
  if opt.SkipUnfinished,
    warning('last active phase has no end marker (skipped)');
  else
    blk = cat(1, blk, [mrk_start, mrk.time(end)]);
    warning('last active phase has no end marker (took last marker instead)');
  end
end

blk= struct('ival',blk);
blk.y= ones(1, size(blk.ival,1));
