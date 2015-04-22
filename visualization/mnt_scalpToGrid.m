function mnt= mnt_scalpToGrid(mnt, varargin)
%MNT_SCALPTOGRID - Montage for grid plot with boxes at scalp locations
%
%Usage:
% MNT= mnt_scalpToGrid(MNT, <OPTS>)
%
%Input:
% MNT: Display montage
% OPTS: property/value list or struct of optional properties:
%  .CLab     - choose only locations for those specified channels,
%              cell array, for format see function util_chanind.
%  .AxisSize - [width Height]: size of axis. Default [] means choosing
%              automatically the large possible size, without overlapping.
%  .Oversize - factor to increase AxisSize to allow partial overlapping,
%              default 1.2.
%  .MaximizeAngle - when choosing automatically the AxisSize, the
%              criterium is to maximize size in direction of this angle.
%  .LegendPos - [hpos VPos], where hpos=0 means leftmost, and hpos=1 means
%              rightmost edge, and VPos=0 means lower and VPos=1 means
%              upper edge.
%  .ScalePos  - [hpos VPos], analog to .LegendPos
%  .PosCorrection - type of corrections for channel positions. There
%              are some popular variants hard coded here. Default 0.
%
%Output:
% MNT: Updated display montage
%
%See also setDisplayMontage, projectElectrodePositions, grid_plot,
% mnt_restrictMontage

props = {'AxisSize',            [],             'DOUBLE';
         'Clab',                [],             'CELL{CHAR}';
         'Oversize',            1.2,            'DOUBLE[1-2]';
         'MaximizeAngle',       60,             'DOUBLE';
         'LegendPos',           [0 0],          'DOUBLE[2]';
         'ScalePos',            [1 0],          'DOUBLE[2]';
         'PosCorrection',       0,              'BOOL'};

if nargin==0,
  mnt= props; return
end

opt= opt_proplistToStruct(varargin{:});
opt= opt_setDefaults(opt, props);

opt_checkProplist(opt, props);

if length(opt.Oversize)==1,
  opt.Oversize= opt.Oversize*[1 1];
end

chind= find(~isnan(mnt.x));
if ~isempty(opt.clab),
  chind= setdiff(chind, util_chanind(mnt, opt.clab),'legacy');
end

mnt.box= NaN*zeros(2,length(mnt.clab)+1);
mnt.box(:,chind)= [mnt.x(chind)'; mnt.y(chind)'];

if isempty(opt.AxisSize) | isequal(opt.AxisSize, 'auto'),
  min_dx= inf;
  min_dy= inf;
  for ii= 1:length(chind)-1,
    for jj= ii+1:length(chind),
      mini= min(mnt.box(:,chind([ii jj])), [], 2);
      maxi= max(mnt.box(:,chind([ii jj])), [], 2);
      dx= maxi(1)-mini(1);
      dy= maxi(2)-mini(2);
      ang= 180/pi* atan2(dx, dy);
      if ang<opt.MaximizeAngle,
        if dy<min_dy,
          min_dy= dy;
        end
      else
        if dx<min_dx,
          min_dx= dx;
        end
      end
    end
  end
  opt.AxisSize= [min_dx min_dy];
end

mnt.box_sz= diag(opt.Oversize)*opt.AxisSize(:)*ones(1,size(mnt.box,2));

mi_x= min(mnt.x(chind));
ma_x= max(mnt.x(chind));
mi_y= min(mnt.y(chind));
ma_y= max(mnt.y(chind));
if size(mnt.box,2)>length(mnt.clab),
  mnt.box(:,end)= [mi_x*(1-opt.LegendPos(1))+ma_x*opt.LegendPos(1); ...
                   mi_y*(1-opt.LegendPos(2))+ma_y*opt.LegendPos(2)];
end

if isfield(mnt, 'scale_box'),
  mnt.scale_box= [mi_x*(1-opt.ScalePos(1))+ma_x*opt.ScalePos(1); ...
                  mi_y*(1-opt.ScalePos(2))+ma_y*opt.ScalePos(2)];
  mnt.scale_box_sz= diag(opt.Oversize)*opt.AxisSize(:);
end

switch(opt.PosCorrection),
 case 1,
  ci= util_chanind(mnt, 'AF3,4');
  mnt.box(:,ci)= [-0.2 0.2; 0.75 0.75];
  ci= util_chanind(mnt, 'PO7,8');
  mnt.box(:,ci)= [-0.45 0.45; -0.65 -0.65];
  ci= util_chanind(mnt, 'TP7,8');
  mnt.box(:,ci)= [-0.68 0.68; -0.37 -0.37];
end
