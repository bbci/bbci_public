function H= gridutil_addScale(mnt, varargin)
%GRIDUTIL_ADDSCALE - Add a Scale for X- and Y-Axis Units to a a Grid Plot
%
%Synopsis:
% H= gridutil_addScale(MNT, <OPT>)
%
%Input:
% MNT: struct for electrode montage, see setElectrodeMontage
% OPT: struct or property/value list of optional properties:
%  .XUnit - Unit of X-Axis, default: 'ms'
%  .YUnit - Unit of Y-Axis, default: '\muV'
%   
% Usually called by grid_plot

props = {'XUnit',                   'ms',                   'CHAR';
         'YUnit',                   '\muV',                 'CHAR';
         'YDir',                    'normal',               'CHAR';
         'ScaleHPos',               'zeroleft',             'CHAR';
         'ScaleVPos',               'zeromiddle',           'CHAR';
         'ScaleFontSize',           get(gca, 'FontSize'),   'DOUBLE';
         'ScaleShowOrientation',    1                       'BOOL'};

if nargin==0,
  H= props; return
end
opt= opt_proplistToStruct(varargin{:});
opt= opt_setDefaults(opt, props);
opt_checkProplist(opt, props);

xLim= get(gca, 'xLim');
yLim= get(gca, 'yLim');
xt= get(gca, 'xTick');
xx= median(diff(xt));
yt= get(gca, 'yTick');
yy= median(diff(yt));

x= [mnt.box(1,:) mnt.scale_box(1)];
y= [mnt.box(2,:) mnt.scale_box(2)];
w= [mnt.box_sz(1,:) mnt.scale_box_sz(1)];
h= [mnt.box_sz(2,:) mnt.scale_box_sz(2)];
bs= 0.005;
siz= (1+2*bs)*[max(x+w) - min(x) max(y+h) - min(y)];
pos= [mnt.scale_box(1)-min(x) mnt.scale_box(2)-min(y) ...
      mnt.scale_box_sz(1) mnt.scale_box_sz(2)]./[siz siz];
pos= pos + [bs bs 0 0];
H.ax= axes('position', pos);
ud= struct('type','ERP plus', 'chan','scale');
set(H.ax, 'xLim',xLim, 'yLim',yLim, 'userData',ud);

if strncmp('zero', opt.ScaleHPos, 4),
  if xLim(1)<0-0.1*diff(xLim) & xLim(2)>xx,
    opt.ScaleHPos= 'Zero';
  else
    opt.ScaleHPos= opt.ScaleHPos(5:end);
    if isempty(opt.ScaleHPos), opt.ScaleHPos= 'middle'; end
  end
end
if strncmpi('zero', opt.ScaleVPos, 4),
  if yLim(1)<0-0.1*diff(yLim) & yLim(2)>yy+0.1*diff(yLim),
    opt.ScaleVPos= 'Zero';
  else
    opt.ScaleVPos= opt.ScaleVPos(5:end);
    if isempty(opt.ScaleVPos), opt.ScaleVPos= 'middle'; end
  end
end

if isfield(opt, 'CLim')
   set(H.ax, 'CLim', opt.CLim')
   if isfield(opt, 'colormap')
      colormap(opt.Colormap); 
   end
   cb = Colorbar;
   opt.ScaleHPos = 'left';
   ap = get(H.ax, 'position');
   set(cb, 'position', [ap(1)+0.8*ap(3) ap(2)+0.1*ap(4) 0.1*ap(3) 0.8*ap(4)])
  set(get(cb,'yLabel'),'String', opt.zUnit)
end

switch(opt.ScaleHPos),
 case 'Zero',
  x0= 0;
 case 'left',
  x0= xLim(1) + 0.05*diff(xLim);
 case 'middle',
  x0= mean(xLim) - xx/2;
 case 'right',
  x0= xLim(2) - xx - 0.05*diff(xLim);
 otherwise,
  error('unimplemented choice for opt.ScaleHPos');
end
switch(opt.ScaleVPos),
 case 'Zero',
  y0= 0;
% case 'top',
%  y0= yLim(2),
 case 'middle',
  y0= mean(yLim) - yy/2;
% case 'bottom',
%  y0= yLim(1);
 otherwise,
  error('unimplemented choice for opt.ScaleVPos');
end

H.vline= line([x0 x0], [y0 y0+yy]);
set(H.vline, 'LineWidth',2, 'Color','k');
H.text_YUnit= text(x0, y0+yy/2, sprintf(' %g %s', yy, opt.YUnit));
set(H.text_YUnit, 'verticalAli','middle', 'FontSize',opt.ScaleFontSize);
if opt.ScaleShowOrientation,
  if strcmpi(opt.YDir, 'reverse'),
    sgn= '-';
  else
    sgn= '+';
  end
  H.text_sgn= text(x0, y0+yy, [' ' sgn]);
  set(H.text_sgn, 'verticalAli','bottom', 'FontSize',opt.ScaleFontSize);
end

H.hline= line([x0 x0+xx], [y0 y0]);
set(H.hline, 'LineWidth',2, 'Color','k');
yt= y0-0.03*diff(yLim);
H.text_XUnit= text(x0+xx/2, yt, ...
                   sprintf('%g %s', xx, opt.XUnit));
set(H.text_XUnit, 'horizontalAli','center', 'verticalAli','top', ...
                  'FontSize',opt.ScaleFontSize);
if x0==xLim(1), %% leftmost position
  set(H.text_XUnit, 'position',[x0 yt 0], 'horizontalAli','left');
end

axis off;

if nargout==0,
  clear H;
end
