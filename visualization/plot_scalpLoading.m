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

props = {'ShowLabels',          1,          'BOOL';
         'ScalePos',            'vert',     'CHAR';
         'FontSize',            8,          'DOUBLE';
         'MinorFontSize',       6,          'DOUBLE';
         'TextColor',           'k',        'CHAR|DOUBLE[3]';
         'CLim',                'sym',      'CHAR(sym range 0tomax)|DOUBLE[2]';
         'DrawNose',            1,          'BOOL';
         'LineWidth',           2,          'DOUBLE';
         'LineColor',           'k',        'CHAR';
         'Radius',              0.074,      'DOUBLE'};

if nargin==0,
  H= props; return
end

opt= opt_proplistToStruct(varargin{:});
opt= opt_setDefaults(opt, props);
opt_checkProplist(opt, props);

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

% Head
H.ax= gca;
T= linspace(0, 2*pi, 360);
xx= cos(T);
yy= sin(T);
H.head= plot(xx, yy, 'k');
hold on;

% Electrodes
T= linspace(0, 2*pi, 18);
disc_x= opt.Radius*cos(T); 
disc_y= opt.Radius*sin(T);

for ic= 1:length(DisplayChannels),
  patch(xe(ic)+disc_x, ye(ic)+disc_y, w(ic));
  h= line(xe(ic)+disc_x, ye(ic)+disc_y);
  set(h, 'Color',opt.LineColor, 'LineWidth',opt.LineWidth);
end
caxis(opt.CLim);


% Nose
if opt.DrawNose,
  nose= [1 1.1 1];
  nosi= [86 90 94]+1;
  H.nose= plot(nose.*xx(nosi), nose.*yy(nosi), 'k');
end

% Labels
if opt.ShowLabels,
  labs= {mnt.clab{DisplayChannels}};
  H.label_text= text(xe, ye, labs);
  set(H.label_text, 'horizontalAlignment','center', ...
         'FontSize',opt.FontSize, 'Color',opt.TextColor);
  strLen= cellfun(@length,labs);
  iLong= find(strLen>3);
  set(H.label_text(iLong), 'FontSize',opt.MinorFontSize);
end

hold off;
set(H.ax, 'xTick', [], 'yTick', []);
axis('xy', 'tight', 'equal', 'tight', 'off');

if nargout==0,
  clear H;
end
