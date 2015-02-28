function H= plot_scalpLoading(mnt, w, varargin)
%PLOT_SCALPLOADING - Visualize single channel loadings of a weight vector
%
%Description:
% This function visualizes the weight vector w as color coded circles at
% the corresponding electrode positions on a scalp outline.
%
%Usage:
% H= plot_scalpLoading(MNT, W, <OPT>)
%
%Input:
% MNT: An electrode montage, see mnt_setElectrodePositions
% W:   Vector to be displayed as scalp topography. The length of W must
%      concide with the length of MNT.clab or the number of non-NaN
%      entries of MNT.x, or OPT must include a field 'WClab'.
% OPT: struct or property/value list of optional properties:
%  .CLim       - 'range', 'sym' (default), '0tomax', 'minto0',
%                or [minVal maxVal]
%  .ShowLabels - Display channel names (1) or not (0), default 1.
%
%Output:
% H:     handle to several graphical objects

props = {'ShowLabels',          1,          'BOOL'
         'ScalePos',            'vert',     'CHAR'
         'UsePatches'           false       'BOOL'
         'FontSize',            8,          'DOUBLE'
         'MinorFontSize',       6,          'DOUBLE'
         'TextColor',           'k',        'CHAR|DOUBLE[3]'
         'CLim',                'sym',      'CHAR(sym range 0tomax)|DOUBLE[2]'
         'LineWidth',           2,          'DOUBLE'
         'LineColor',           'k',        'CHAR'
         'Radius',              0.074,      'DOUBLE'
         'NApprox',             18,         'INT'};

props_scalpOutline = plot_scalpOutline;

if nargin==0,
  H= opt_catProps(props, props_scalpOutline); return
end

opt= opt_proplistToStruct(varargin{:});
[opt, isdefault]= opt_setDefaults(opt, props);
opt_checkProplist(opt, props, props_scalpOutline);

opt_scalpOutline= opt_substruct(opt, props_scalpOutline(:,1));
 
tight_caxis= [min(w) max(w)];
if isequal(opt.CLim, 'sym'),
  zgMax= max(abs(tight_caxis));
  opt.CLim= [-zgMax zgMax];
elseif isequal(opt.CLim, 'range'),
  opt.CLim= [min(tight_caxis) max(tight_caxis)];
elseif isequal(opt.CLim, '0tomax'),
  opt.CLim= [0.0001 max(tight_caxis)];
end
caxis(opt.CLim);

w= w(:);
if length(w)==length(mnt.clab),
  DisplayChannels= find(~isnan(mnt.x(:)) & ~isnan(w));
  w= w(DisplayChannels);
else
  DisplayChannels= find(~isnan(mnt.x));
  if length(w)~=length(DisplayChannels),
    error(['length of w must match # of displayable channels, ' ...
           'i.e. ~isnan(mnt.x), in mnt']);
  end
end
xe= mnt.x(DisplayChannels);
ye= mnt.y(DisplayChannels);

if opt.UsePatches,
  T= linspace(0, 2*pi, opt.NApprox);
  disc_x= opt.Radius*cos(T); 
  disc_y= opt.Radius*sin(T);

  for ic= 1:length(DisplayChannels),
    H.patch(ic)= patch(xe(ic)+disc_x, ye(ic)+disc_y, w(ic));
  end
  set(H.patch, 'EdgeColor',opt.LineColor, 'LineWidth',opt.LineWidth);
  H= plot_scalpOutline(mnt, opt_scalpOutline, 'H',H, ...
                       'DisplayChannels',DisplayChannels);
  delete(H.label_markers);
else
  opt_scalpOutline.MarkerProperties= ...
      {'Marker','o', 'MarkerSize',32/0.1*opt.Radius, ...
       'MarkerEdgeColor','k', 'LineWidth',2};
  H= plot_scalpOutline(mnt, opt_scalpOutline, ...
                       'DisplayChannels',DisplayChannels);
  cmap= colormap;
  nColors= size(cmap,1);
  CLim= get(H.ax, 'CLim');
  ci= round( nColors * (w-CLim(1))/diff(CLim) );
  ci= min(max(ci, 1), nColors);
  for chan= 1:length(DisplayChannels),
    set(H.label_markers(chan), 'MarkerFaceColor',cmap(ci(chan),:));
  end
end

if strcmp(opt.ScalePos, 'none'),
  H.cb= [];
else
  H.cb= colorbar(opt.ScalePos);
end
axis('off');

if nargout==0,
  clear H;
end
