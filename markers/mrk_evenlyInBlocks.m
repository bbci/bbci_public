function mrk= mrk_evenlyInBlocksNew(blk, msec, varargin)

% MRK_EVENLYINBLOCKS - inserts additional markers between the existing
% markers, starting msec after the existing markers.
%
% Synopsis:
%   [MRK]= mrk_evenlyInBlocks(mrk, msec, <OPT>)
%
% Arguments:
%   MRK: marker structure
%   MSEC: length of each block in milliseconds
%
% Opt - struct or property/value list of optional fields/properties:
%      .OffsetStart -  specify offset in milliseconds after which the first
%                       after an existing marker block is to be set (default 0)
%      .OffsetEnd -    minimum length between block and next marker (default msec) 
%
% Returns:
%   MRK: updated marker structure

% Author: Benjamin B
% 7-2010: Documented, extended, cleaned up (Matthias T)
% 5- 2015 adapted to the new toolbox (Laura A, Benjamin B, Markus W)

props= {'OffsetEnd'     msec   'DOUBLE'
        'OffsetStart'   0      'DOUBLE'
       };
   
opt= opt_proplistToStruct(varargin{:});
opt= opt_setDefaults(opt, props, 1);
opt_checkProplist(opt, props); 

misc_checkType(blk, 'STRUCT');
misc_checkType(msec, 'DOUBLE');

mrk= struct('time',[], 'event',struct);
mrk.event= struct('blkno',[]);

if isfield(blk, 'y'),
  [nClasses, nBlocks]= size(blk.y);
  mrk.y= zeros(nClasses,0);
  mrk.className= blk.className;
end

nBlocks= size(blk.ival,2);
for bb= 1:nBlocks,
  new_time= blk.ival(1,bb)+opt.OffsetStart:msec:blk.ival(2,bb)-opt.OffsetEnd;
  nMrk= length(new_time);
  mrk.time= cat(2, mrk.time, new_time);
  mrk.event.blkno= cat(2, mrk.event.blkno, bb*ones(1,length(new_time)));
  if isfield(blk, 'y'),
    new_y= zeros(nClasses, nMrk);
    iClass= find(blk.y(:,bb));
    new_y(iClass,:)= 1;
    mrk.y= cat(2, mrk.y, new_y);
  end
end