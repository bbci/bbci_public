function h_cb= plotutil_colorbarAside(varargin)
%PLOT_COLORBARASIDE - Add a colorbar without shrinking the axis
%
%Synopsis:
% H_CB= plotutil_colorbarAside(<OPT>)
% H_CB= plotutil_colorbarAside(ORIENTATION, <OPT>)
%
%Input:
% ORIENTATION: see OPT.Orientation
% OPT: struct or property/value list of optional properties
%  .orientation - orientation resp. location of the colorbar relative
%                 to the axis: 'vert','horiz', 'NorthOutside',
%                 'EastOutside','SouthOutside', 'WestOutside'
%
%Output:
% HCB: handle of the colorbar
%
%Note:
% So far, plotutil_colorbarAside is compatible with Matlab 6, but it allows
% the new orientation modes of Matlab 7.

% blanker@cs.tu-berlin.de

props = {'Orientation'      'vert'      '!CHAR(vert horiz NorthOutside EastOutside SouthOutside WestOutside)';
         'Gap'              0.02        '!DOUBLE';
         };

if mod(nargin, 2)==1,
  varargin = {'Orientation'  varargin{:}};
end

opt= opt_proplistToStruct(varargin{:});
[opt,isdefault] = opt_setDefaults(opt, props);
opt_checkProplist(opt, props);

ax= gca;
pos= get(ax, 'position');
% this has an influence on the behavious when resizing the figure:
epos= axis_getEffectivePosition(ax);
% this would require Matlab 7:
% h_cb= colorbar(opt.Orientation);
if ismember(lower(opt.Orientation), {'horiz','northoutside','southoutside'},'legacy'),
  h_cb= colorbar('horiz');
%  h_cb= colorbar('SouthOutside');
else
  h_cb= colorbar('EastOutside');
end
set(ax, 'position',pos);
drawnow;
cb_pos= get(h_cb, 'position');
%ii= strmatch(opt.Orientation, {'vert','horiz'}, 'exact');
%cb_pos(ii)= pos(ii)+pos(ii+2)+0.02;
%cb_pos(5-ii)= min(cb_pos(5-ii), epos(5-ii));
%cb_pos(3-ii)= pos(3-ii) + (pos(5-ii)-cb_pos(5-ii))/2;
switch(lower(opt.Orientation)),
 case {'vert','eastoutside'},
  cb_pos(1)= pos(1) + pos(3) + opt.Gap;
  cb_pos(4)= min(cb_pos(4), epos(4));
  cb_pos(2)= pos(2) + (pos(4)-cb_pos(4))/2;
 case 'westoutside',
  cb_pos(1)= pos(1) - cb_pos(3) - opt.Gap;
  cb_pos(4)= min(cb_pos(4), epos(4));
  cb_pos(2)= pos(2) + (pos(4)-cb_pos(4))/2;
  set(h_cb, 'YAxisLocation','left');
 case {'horiz','southoutside'},
  cb_pos(2)= pos(2) - cb_pos(4) - opt.Gap;
  cb_pos(3)= min(cb_pos(3), epos(3));
  cb_pos(1)= pos(1) + (pos(3)-cb_pos(3))/2;
 case 'northoutside',
  cb_pos(2)= pos(2) + pos(4) + opt.Gap;
  cb_pos(3)= min(cb_pos(3), epos(3));
  cb_pos(1)= pos(1) + (pos(3)-cb_pos(3))/2;
  set(h_cb, 'XAxisLocation','top');
 otherwise,
  error('unknown orientation/location');
end
set(h_cb, 'Position',cb_pos);
%delete(h_cb);
%cb_ax= axes('position',cb_pos);
%h_cb= colorbar(cb_ax, 'peer',ax);

if nargout==0,
  clear h_cb;
end
