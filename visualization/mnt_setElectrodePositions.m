function mnt= mnt_setElectrodePositions(clab, varargin)
%MNT_SETELECTRODEPOSITIONS - Electrode positions of standard named channels
%
%Synopsis:
% MNT= mnt_setElectrodePositions(CLAB, <OPT>);
%
%Input:
% CLAB: Label of channels (according to the extended international
%       10-10 system, see mntutil_posExt1010).
% OPT: Struct or property/value list of optional properties:
%  .PositionFcn - FUNC handle of function that specifies eletrode positions,
%                 default @mntutil_posExt1010
%
%Output:
% MNT: Struct for electrode montage
%  .x     - x coordiante of electrode positions
%  .y     - y coordinate of electrode positions
%  .clab  - channel labels
%
%See also mnt_setGrid


props= {'PositionFcn'   @mntutil_posExt1010   'FUNC'
        };
opt= opt_proplistToStruct(varargin{:});
opt= opt_setDefaults(opt, props, 1);

posSystem= opt.PositionFcn();
x= posSystem.x;
y= posSystem.y;
z= posSystem.z;
elab= posSystem.clab;

maz= max(z(:));
miz= min(z(:));
% ALTERNATIVE PROJECTION:
% This function works with an input of mnt which assumes that the human head "is" a ball with radius 1.
% The lower section of this ball is first projected onto the walls of a cylinder (orthogonal, with radius 1);
% then all (new) points will be projected on the 2d-hyperspace with z=maz.
%ur= [0 0 miz-0.8*(maz-miz)];
% ur is the center of projection. This is why the function only works with radius = 1 
% and ur(1:2) = [0 0].
ur= [0 0 -1.5];
if 1==0% old projection. uses center of projection.
  la= (maz-ur(3)) ./ (z(:)-ur(3));
  Ur= ones(length(z(:)),1)*ur;
  % Project the lower halfball onto the wall of the cylinder:
  cx = x;
  cy = y;
  cx(z<0) = cx(z<0)./sqrt(cx(z<0).^2+cy(z<0).^2);
  cy(z<0) = cy(z<0)./sqrt(cx(z<0).^2+cy(z<0).^2);
  % Project everything onto the plane {z = maz}:
  pos2d= Ur + (la*ones(1,3)) .* ([cx(:) cy(:) z(:)] - Ur);
  pos2d= pos2d(:, 1:2);
  %pos2d(z<0,:)= NaN;% TODO: don't throw away the values of the lower halfball!
end

% This projection uses the distance on the "head"-surface to determine the 2d-positions of the electrodes w.r.t. Cz.
alpha = asin(sqrt(x.^2 + y.^2));
stretch = 2-2*abs(alpha)/pi;
stretch(z>0) = 2*abs(alpha(z>0))/pi;
norm = sqrt(x.^2 + y.^2);
norm(norm==0) = 1;
cx = x.*stretch./norm;
cy = y.*stretch./norm;
pos2d = [cx(:) cy(:)];

nChans= length(clab);
mnt.x= NaN*ones(nChans, 1);
mnt.y= NaN*ones(nChans, 1);
mnt.pos_3d= NaN*ones(3, nChans);
for ei= 1:nChans,
  ii= util_chanind(elab, clab{ei});
  if ~isempty(ii),
    mnt.x(ei)= pos2d(ii, 1);
    mnt.y(ei)= pos2d(ii, 2);
    mnt.pos_3d(:,ei)= [x(ii) y(ii) z(ii)];
  end
end
radius = 1.3;
%radius= 1.9;
mnt.x= mnt.x/radius;
mnt.y= mnt.y/radius;
mnt.clab= clab;
