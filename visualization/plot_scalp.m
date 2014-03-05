function [H, Ctour]= plot_scalp(mnt, w, varargin)
%PLOT_SCALP - Display a weight vector as scalp topography
%
%Description:
% This is the low level function for displaying a scalp topography.
% In many cases it is more wise to use one of the other plot_scalp*
% functions.
%
%Synopsis:
% H= plot_scalp(MNT, W, <OPT>)
%
%Input:
% MNT: An electrode montage, see mnt_setElectrodePositions
% W:   Vector to be displayed as scalp topography. The length of W must
%      concide with the length of MNT.clab or the number of non-NaN
%      entries of MNT.x, or OPT must include a field 'WClab'.
%      Warning: when you do not specify OPT.WClab you have to make sure
%      that the entries of W are matching with MNT.clab, or
%      MNT.clab(find(~isnan(MNT.x))).
% OPT: struct or property/value list of optional properties:
%  .CLim          - 'range', 'sym' (default), '0tomax', 'minto0',
%                   or [minVal maxVal]
%  .ScalePos      - Placement of the Colorbar 'horiz', 'vert' (default), 
%                   or 'none'
%  .Contour       - Specifies at what Heights contour lines are drawn.
%                   If 'contour' is a vector, its entries define the
%                   Heights. If is a scalar it specifies
%                   (according to 'ContourPolicy') the number
%                   of or the spacing between contour levels. To display
%                   no contour lines set 'contour' to 0 (not []!).
%  .ContourPolicy - 'levels' (default): 'contour' specifies exactly the
%                   number of contour levels to be drawn, or
%                   'spacing': 'contour' specifies the spacing between two
%                   adjacent Height levels, or
%                   'choose': '.contour' specifies approximately the
%                   number of Height levels to be drawn, but the function
%                   'goodContourValues' is called to find nice values.
%  .Resolution    - default 40. Number of steps around circle used for
%                   plotting the scalp.
%  .ShowLabels    - Display channel names (1) or not (0), default 0.
%  .Shading         shading method for the pColor plot, default 'flat'.
%                   Use 'interp' to get nice, smooth plots. But saving
%                   needs more space.
%  .Extrapolation - Default value (1) extends the scalp plot to the
%                   peripheral areas where no channels are located.
%                   Value (0) turns off extrapolation.
%  .ExtrapolateToMean - Default value (1) paints peripheral area
%                   in Color of average (zero?) value. Needs .Extrapolation 
%                   activated. 
%  .ExtrapolateToZero - Value (1) paints peripheral area in "zero"-Color.
%                   Needs .Extrapolation activated. 
%  .Renderer      - The function used for rendering the scalp map, 'pColor'
%                   or 'contourf' (default).
%  .ContourfLevels - number of levels for contourf function (default 100).
%  .Offset        - a vector of length 2  -  [x_Offset y_Offset]
%                   normally, the scalpplot is drawn centered at the origin,
%                   i.e. [x_Offset y_Offset] = [0 0] by default
%
%Output:
% H:     handle to several graphical objects
% Ctour: struct of contour information
%
%See also plot_scalpPatterns, plot_scalpEvolution.

% Author(s): Benjamin Blankertz, Aug 2000; Feb 2005, Matthias
% Added contourf: Matthias Treder 2010
% Added "ExtrapolateToZero" option: Simon Scholler, 2011
% "Offset" option added: Simon Scholler, 2011

props= {
        'CLim',                 'sym',             'CHAR|DOUBLE[2]';
        'Colormap',              get(gcf,'Colormap'), 'DOUBLE[- 3]';
        'ContourfLevels',        50,               'DOUBLE[1]';
        'ContourMargin',         0,                'DOUBLE[1]';
        'Contour',               5,                'DOUBLE';
        'ContourPolicy',         'levels',         'CHAR';
        'ContourLineprop',       {'LineWidth',1},  'PROPLIST';
        'ContourLabels',         0,                'BOOL';
        'Extrapolation',         1,                'BOOL';
        'ExtrapolateToMean',     0,                'BOOL';
        'ExtrapolateToZero',     0,                'BOOL';
        'Interpolation',         'linear',         'CHAR';
        'LineProperties',        {'k'},            'CELL';
        'MarkContour',           [],               'DOUBLE[0-2]';
        'MarkContourLineprop',   {'LineWidth',2},  'PROPLIST';
        'NewColormap',           0,                'BOOL';
        'Offset',                [0 0],            'DOUBLE[2]';
        'Resolution',            51,               'DOUBLE[1]';
        'Renderer',              'contourf',       'CHAR';
        'Shading',               'flat',           'CHAR';
        'ShrinkColorbar',        0,                'DOUBLE';
        'ScalePos',              'vert',           'CHAR';
        'TicksAtContourLevels',  1,                'BOOL';
        'WClab',                 {},               'CELL{CHAR}';
        };

props_scalpOutline = plot_scalpOutline;

if nargin==0,
  H= opt_catProps(props, props_scalpOutline); return
end

opt= opt_proplistToStruct(varargin{:});
[opt, isdefault]= opt_setDefaults(opt, props);
opt_checkProplist(opt, props, props_scalpOutline);

opt_scalpOutline= opt_substruct(opt, props_scalpOutline(:,1));

if opt.NewColormap,
  acm= visutil_addColormap(opt.Colormap);
elseif isfield(opt, 'Colormap'),
  colormap(opt.Colormap);
end

if opt.Extrapolation,
  if isdefault.LineProperties,
    opt.LineProperties= {'Color','k', 'LineWidth',3};
  end
  if isdefault.Resolution,
    opt.Resolution= 101;
  end
end

w= w(:);
if ~isempty(opt.WClab),
  mnt= mnt_adaptMontage(mnt, opt.WClab);
  if length(mnt.clab)<length(opt.WClab),
    error('some channels of opt.WClab not found in montage');
  end
end
if length(w)==length(mnt.clab),
  DisplayChannels= find(~isnan(mnt.x));
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

H.ax= gca;
if isempty(opt.Resolution)
  oldUnits= get(H.ax, 'units');
  set(H.ax, 'units', 'normalized');
  pos= get(H.ax, 'position');
  set(H.ax, 'units', oldUnits);
  opt.Resolution= max(20, 60*pos(3)); 
end

% Allow radius of scalp data to go beyond scalp outline (>1)
maxrad = max(1,max(max(abs(mnt.x)),max(abs(mnt.y)))) + opt.ContourMargin; 

% Extrapolation
if opt.Extrapolation,
  xx= linspace(-maxrad, maxrad, opt.Resolution);
  yy= linspace(-maxrad, maxrad, opt.Resolution)';
  if opt.ExtrapolateToMean
    xe_add = cos(linspace(0,2*pi,opt.Resolution))'*maxrad;
    ye_add = sin(linspace(0,2*pi,opt.Resolution))'*maxrad;
    w_add = ones(length(xe_add),1)*mean(w);
    xe = [xe;xe_add];
    ye = [ye;ye_add];
    w = [w;w_add];
  end
  if opt.ExtrapolateToZero
    xe_add = cos(linspace(0,2*pi,opt.Resolution))';
    ye_add = sin(linspace(0,2*pi,opt.Resolution))';
    xe = [xe;xe_add];
    ye = [ye;ye_add];
    w = [w; zeros(length(xe_add),1)];
  end
  
else
  xx= linspace(min(xe), max(xe), opt.Resolution);
  yy= linspace(min(ye), max(ye), opt.Resolution)';
end

if opt.Extrapolation,
  wstate= warning('off');
  [xg,yg,zg]= griddata(xe, ye, w, xx, yy, 'v4');
  warning(wstate);
  margin = maxrad +opt.ContourMargin;
  headmask= (sqrt(xg.^2+yg.^2)<=margin);
  imaskout= ~headmask;
  zg(imaskout)= NaN;
  
else
  if strcmp(opt.Interpolation, 'v4'),
    % get the convex hull from linear Interpolation
    [dummy1,dummy2,zconv]= griddata(xe, ye, w, xx, yy, 'linear');
    imaskout= isnan(zconv(:));
    [xg,yg,zg]= griddata(xe, ye, w, xx, yy, opt.Interpolation);
    zg(imaskout)= NaN;
  else
    [xg,yg,zg]= griddata(xe, ye, w, xx, yy, opt.Interpolation);
  end
end

xs= xg(1,2)-xg(1,1);
ys= yg(2,1)-yg(1,1);

% contour line coordinated
xgc= xg+opt.Offset(1);
ygc= yg+opt.Offset(2);
zgc= zg;
if ~isempty(strmatch(lower(opt.Shading), {'flat','faceted'})) ... 
    && strcmp(opt.Renderer,'pColor'),
  % in shading FLAT last row/column is skipped, so add one
  xg= [xg-xs/2, xg(:,end)+xs/2];
  xg= [xg; xg(end,:)];
  yg= [yg, yg(:,end)]-ys/2;
  yg= [yg; yg(end,:)+ys];
  zg= [zg, zg(:,end)];
  zg= [zg; zg(end,:)];
end

% Render using pColor or contourf
xg= xg+opt.Offset(1);
yg= yg+opt.Offset(2);
if strcmp(opt.Renderer,'pColor')
  H.patch= pColor(xg, yg, zg);
else
  [dummy,H.patch]= contourf(xg, yg, zg, opt.ContourfLevels,'LineStyle','none');
  % *** Hack to enforce cdatamappig = scaled in Colorbarv6.m by introducing
  % a useless patch object
  hold on
  patch([0 0],[0 0],[1 2]);
  ccc = get(gca,'children');
  set(ccc(1),'Visible','off');
end

%
tight_caxis= [min(zg(:)) max(zg(:))];
if isequal(opt.CLim, 'sym'),
  zgMax= max(abs(tight_caxis));
  H.CLim= [-zgMax zgMax];
elseif isequal(opt.CLim, 'range'),
  H.CLim= tight_caxis;
elseif isequal(opt.CLim, '0tomax'),
  H.CLim= [0.0001*diff(tight_caxis) max(tight_caxis)];
elseif isequal(opt.CLim, 'minto0'),
  H.CLim= [min(tight_caxis) -0.0001*diff(tight_caxis)];
elseif isequal(opt.CLim, 'zerotomax'),
  H.CLim= [0 max(tight_caxis)];
elseif isequal(opt.CLim, 'mintozero'),
  H.CLim= [min(tight_caxis) 0];
else
  H.CLim= opt.CLim;
end
if diff(H.CLim)==0, H.CLim(2)= H.CLim(2)+eps; end
set(gca, 'CLim',H.CLim);

if strcmp(opt.Renderer,'pColor')
  shading(opt.Shading);
end

hold on;
if ~isequal(opt.Contour,0),
  if length(opt.Contour)>1,
    ctick= opt.Contour;
    v= ctick;
  else
    mi= min(H.CLim);
    ma= max(H.CLim);
    switch(opt.ContourPolicy),
     case {'levels','strict'},
      ctick= linspace(mi, ma, abs(opt.Contour)+2);
      v= ctick([2:end-1]);
     case 'withinrange',
      ctick= linspace(min(tight_caxis), max(tight_caxis), abs(opt.Contour)+2);
      v= ctick([2:end-1]);
     case 'spacing',
      mm= max(abs([mi ma]));
      v= 0:opt.Contour:mm;
      v= [fliplr(-v(2:end)), v];
      ctick= v(v>=mi & v<=ma);
      v(v<=mi | v>=ma)= [];
     case 'spacing_compatability',
      v= floor(mi):opt.Contour:ceil(ma);
      ctick= v(v>=mi & v<=ma);
      v(v<=mi | v>=ma)= [];
     case 'choose',
      ctick= visutil_goodContourValues(mi, ma, -abs(opt.Contour));
      v= ctick;
     otherwise
      error('ContourPolicy not known');
    end
  end
  v_tmp= v;
  if length(v)==1,
    v_tmp= [v v];
  end
  if isempty(v),
    H.contour= [];
  else
    [c,H.contour]= contour(xgc, ygc, zgc, v_tmp, 'k-');
    set(H.contour, opt.ContourLineprop{:});
    if opt.ContourLabels, %% & length(H.contour)>1,
      clabel(c,H.contour);
    end
  end
  H.contour_Heights= v;
else
  H.contour_Heights = [];   %% recently added
end
if ~isempty(opt.MarkContour),
  if length(opt.MarkContour)==1,
    v_tmp= [1 1]*opt.MarkContour;
  else
    v_tmp= opt.MarkContour;
  end
  [c,H.MarkContour]= contour(xgc, ygc, zgc, v_tmp, 'k-');
  set(H.MarkContour, opt.markContourLineprop{:});
end

% Scalp outline
H= plot_scalpOutline(mnt, opt_scalpOutline, 'H',H, 'DisplayChannels',DisplayChannels);

if strcmp(opt.ScalePos, 'none'),
  H.cb= [];
else
  H.cb= colorbar(opt.ScalePos);
  if opt.TicksAtContourLevels && opt.Contour,
    if strcmpi(opt.ScalePos, 'vert'),
      set(H.cb, 'yLim',H.CLim, 'yTick', ctick);
      if opt.ShrinkColorbar>0,
        cbpos= get(H.cb, 'Position');
        cbpos(2)= cbpos(2) + cbpos(4)*opt.ShrinkColorbar/2;
        cbpos(4)= cbpos(4) - cbpos(4)*opt.ShrinkColorbar;
        set(H.cb, 'Position',cbpos);
      end
    else
      set(H.cb, 'xLim',H.CLim, 'xTick', ctick);
      if opt.ShrinkColorbar>0,
        cbpos= get(H.cb, 'Position');
        cbpos(1)= cbpos(1) + cbpos(1)*opt.ShrinkColorbar/2;
        cbpos(3)= cbpos(3) - cbpos(3)*opt.ShrinkColorbar;
        set(H.cb, 'Position',cbpos);
      end
    end
  end
  if ~isempty(H.contour_Heights) && opt.TicksAtContourLevels,
    set(H.cb, 'YTick',H.contour_Heights);
  end
end
if opt.NewColormap,
  visutil_acmAdaptCLim(acm);
  set(H.cb, 'yLim',H.CLim); % otherwise ticks at the border of the
                            % Colorbar might get lost
end
axis('off');

if nargout==0,
  clear H;
end
if nargout>=2,
  if ~exist('c', 'var'),
    c= [];
  end
  Ctour= struct('xgrid',xg, 'ygrid',yg, 'zgrid',zg, ...
                'values',v, 'matrix',c);
end

