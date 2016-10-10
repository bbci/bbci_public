function mrk= mrk_evenlyInBlocks(blk, msec, varargin)

% MRK_EVENLYINBLOCKS - inserts additional markers between the existing
% markers, starting msec after the existing markers.
%
% Synopsis:
%   MRK= mrk_evenlyInBlocks(BLK, MSEC, <OPT>)
%
% Arguments:
%   BLK:  [STRUCT] structure defining blocks. It must have a field 'ival',
%         with each row defining a time interval ('block') in msec.
%          
%   MSEC: [DOUBLE] distance of markers within each block in milliseconds
%
% OPT - struct or property/value list of optional fields/properties:
%      .OffsetStart -  specify offset in milliseconds after which the first
%                      after an existing marker block is to be set (default 0)
%      .OffsetEnd -    minimum length between block and next marker
%                      (default msec) 
%
% Returns:
%   MRK: marker structure 

% Author: Benjamin B
% 7-2010: Documented, extended, cleaned up (Matthias T)
% 5-2015 adapted to the new toolbox (Laura A, Benjamin B, Markus W)

props= {'OffsetEnd'     msec   '!DOUBLE[1]'
        'OffsetStart'   0      '!DOUBLE[1]'
       };
   
opt= opt_proplistToStruct(varargin{:});
opt= opt_setDefaults(opt, props, 1);
opt_checkProplist(opt, props); 

misc_checkType(blk, 'STRUCT(ival)');
misc_checkType(blk.ival, 'DOUBLE[- 2]', 'blk.ival');
misc_checkType(msec, '!DOUBLE[1]');

mrk= struct('time',[], 'event',struct);
mrk.event= struct('blkno',[]);

if isfield(blk, 'y'),
  [nClasses, nBlocks]= size(blk.y);
  mrk.y= zeros(nClasses,0);
  mrk.className= blk.className;
end

% fields from blk.event will be adapted and added to mrk.event. Let's prepare:
if isfield(blk, 'event'),
  eventFields= fieldnames(blk.event);
else
  eventFields= {};
end
for Fld= eventFields,
  fld= Fld{1};
  mrk.event.(fld)= [];
end

nBlocks= size(blk.ival,1);
for bb= 1:nBlocks,
  new_time= blk.ival(bb,1)+opt.OffsetStart:msec:blk.ival(bb,2)-opt.OffsetEnd;
  nMrk= length(new_time);
  mrk.time= cat(2, mrk.time, new_time);
  mrk.event.blkno= cat(1, mrk.event.blkno, bb*ones(nMrk,1)); % blkno has to be column vector for later functions
  % adapt fields from blk.event and add to mrk.event
  for Fld= eventFields,
    fld= Fld{1};
    val= blk.event.(fld)(bb);
    mrk.event.(fld)= cat(1, mrk.event.(fld), repmat(val, [nMrk 1])); 
  end
  if isfield(blk, 'y'),
    new_y= zeros(nClasses, nMrk);
    iClass= find(blk.y(:,bb));
    new_y(iClass,:)= 1;
    mrk.y= cat(2, mrk.y, new_y);
  end
end