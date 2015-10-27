function H= grid_addBars(fv, varargin)
%GRID_ADDBARS - Add a Colorbar to the Bottom of Each Subplot of a Grid Plot
%
%Synopsis:
% H= grid_addBars(FV, <opt>)
%
%Input:
% FV: data structure (like epo)
% OPT: struct or property/value list of optional properties:
%  .Height    - Height of the colorbar
%  .HScale    - Handle to the scale of the grid plot (returned by
%               grid_plot as .scale), a colorbar will be placed next to
%               the scale
%  .ShiftAxes - 'position' or 'ylim'
%  .CLim      - Color limit of colorbar, either a 1-by-2 vector giving
%               the limit or 'auto' (default)
%  .Colormap  - The colormap of colorbar, either a x-by-3 vector giving
%               the explicit map, or one of the predefined maps (see
%               help of 'colormap')
%  .Channels  - Channels for which bar should be added, either a cell
%               of strings giving the channels names, or en empty array
%               for all channels, or 'plus'
%  .Scale*    - with * in {'Height','Width','VPos','LeftShift',
%               'FontSize','Digits','Unit'} define the appearance of
%               the scale
%   
%Output:
%   H - handle to graphic objects
%
%Caveat:
% You have to make sure that the FV data fits to the data that was displayed
% with grid_plot before (e.g. for the length of the vector in the time
% dimension). The channels are matched automatically. FV may have less
% channels than displayed by grid_plot.
%
%Example:
% H= grid_plot(epo, mnt, defopt_erps)
% epo_rsq= proc_r_square_signed(epo);
% grid_addBars(epo_rsq, 'HScale',H.scale)

props= {'VPos',                 0,                      'DOUBLE';
        'Height',               1/15,                   'DOUBLE';
        'ShiftAxes',            'ylim',                 'CHAR';
        'ShiftAlso',            {'scale'},              'CELL{CHAR}';
        'CLim',                 'auto',                 'CHAR|DOUBLE[2]';
        'Colormap',             flipud(gray(32)),       'DOUBLE[- 3]';
        'UseLocalColormap',     1,                      'BOOL';
        'MoveBack',             0,                      'BOOL';
        'Box',                  'on',                   'CHAR';
        'Visible',              'off',                  'CHAR';
        'AlphaStepsMode',       0,                      'BOOL';
        'HScale',               [],                     'STRUCT(ax)';
        'ScaleHeight',          .66,                    'DOUBLE';
        'ScaleWidth',           .075,                   'DOUBLE';
        'ScaleVPos',            .25,                    'DOUBLE';
        'ScaleLeftShift',       .05,                    'DOUBLE';
        'ScaleFontSize',        get(gca,'FontSize'),    'DOUBLE';
        'ScaleDigits',          4                       'DOUBLE';
        'ScaleUnit',            ''                      'CHAR';
        'Channels',             '*'                     'CHAR|DOUBLE'};


if nargin==0,
  H= props; return
end

opt= opt_proplistToStruct(varargin{:});
[opt, isdefault]= opt_setDefaults(opt, props);
opt_checkProplist(opt, props);

if ndims(fv.x)>2
  error('only one Class allowed');
end

if min(fv.x(:))<0,
  if isdefault.CLim,
    opt.CLim= 'sym';
  end
end
if isdefault.Colormap && ...
        (isequal(opt.CLim,'sym') || (isnumeric(opt.CLim) && opt.CLim(1)<0)),
  opt.Colormap= cmap_posneg(21);
end

if isdefault.AlphaStepsMode && ...
      isfield(fv, 'ClassName') && ...
      ~isempty(findstr(fv.ClassName{1},'alpha-steps')),
  opt.AlphaStepsMode= 1;
end
if opt.AlphaStepsMode,
  nValues= length(fv.alpha);
  [opt, isdefault]= ...
      opt_overrideIfDefault(opt, isdefault, ...
                            'CLim', [0 nValues], ...
                            'Colormap', flipud(gray(nValues+1)), ...
                            'ScaleUnit', '%');
end
if isdefault.ScaleUnit && isfield(fv, 'yUnit'),
  opt.ScaleUnit= fv.yUnit;
end
if isdefault.ScaleVPos && isempty(opt.ScaleUnit),
  opt.ScaleVPos= 0.5;
end
if isdefault.Visible && strcmpi(opt.Box, 'on'),
  opt.Visible= 'on';
end
if isdefault.UseLocalColormap,
  if visutil_isColormapUsed && ~isequal(opt.Colormap, get(gcf, 'colormap')),
    opt.UseLocalColormap= 1;
  end
end

[AxesStyle, lineStyle]= opt_extractPlotStyles(opt);

if opt.UseLocalColormap,
  iswhite= find(all(opt.Colormap==1,2));
  if ~isempty(iswhite),
    opt.Colormap(iswhite,:)= 0.9999*[1 1 1];
  end
  H.image= 'sorry: fakeimage - no handle';
else
  set(gcf, 'colormap',opt.Colormap);
end

if isnumeric(opt.Channels)
  ax= opt.Channels;
else
  ax= gridutil_getSubplots(opt.Channels);
end

% For image_localColormap we have to determine the CLim in advance.
% Therefore we need to determine the depicted channels.
% (If only image was used, this functions would be simpler.)
clab= cell(1, length(ax));
for ii= 1:length(ax),
  clab{ii}= getfield(get(ax(ii), 'userData'), 'chan');
  if iscell(clab{ii}),
    clab{ii}= clab{ii}{1};  % for multiple channels per ax, choose only
                            % the first one
  end
end
if strcmpi(opt.CLim, 'auto'),
  ci= util_chanind(fv, clab);
  mi= min(min(fv.x(:,ci)));
  if mi>=0 && isdefault.CLim,
    warning('know-it-all: switching to CLim mode ''0tomax''');
    opt.CLim= '0tomax';
  else
    opt.CLim= [mi max(max(fv.x(:,ci)))];
  end
elseif strcmpi(opt.CLim, 'sym'),
  ci= util_chanind(fv, clab);
  mi= min(min(fv.x(:,ci)));
  ma= max(max(fv.x(:,ci)));
  mm= max(abs(mi), ma);
  opt.CLim= [-mm mm];
end
if strcmpi(opt.CLim, '0tomax'),
  ci= util_chanind(fv, clab);
  opt.CLim= [0 max(max(fv.x(:,ci)))];
end

jj= 0;
for ii= 1:length(ax),
  set(ax(ii), 'YLimMode','manual');
  ud= get(ax(ii), 'userData');
  if iscell(ud.chan),
    ud.chan= ud.chan{1};  % for multiple channels per axis take only the first
  end
  ci= util_chanind(fv, ud.chan);
  if isempty(ci) && isempty(strmatch(ud.chan,opt.ShiftAlso,'exact')),
    continue;
  end
  pos= get(ax(ii), 'position');
  bar_pos= [pos(1:3) opt.Height*pos(4)];
  bar_pos(2)= pos(2) + opt.VPos*(1-opt.Height)*pos(4);
  switch(opt.ShiftAxes)
    case {1,'position'},
     if opt.VPos<0.5,
       new_pos= [pos(1) pos(2)+bar_pos(4) pos(3) pos(4)*(1-opt.Height)];
     else
       new_pos= [pos(1:3) pos(4)*(1-opt.Height)];
       if opt.VPos==1,
         axis_raiseTitle(ax(ii), opt.Height);
       end
     end
     set(ax(ii), 'position',new_pos);
    case {2,'ylim'},
     yLim= get(ax(ii), 'yLim');
     if opt.VPos<0.5,
       yLim(1)= yLim(1) - opt.Height*diff(yLim);
     else
       yLim(2)= yLim(2) + opt.Height*diff(yLim);
     end
     set(ax(ii), 'yLim',yLim);
   otherwise,
    error('ShiftAxes policy not known');
  end
  if isempty(ci),
    continue;
  end
  jj= jj+1;
  H.ax(jj)= axes('position', bar_pos);
  set(H.ax(jj), AxesStyle{:});
  hold on;      % otherwise axis properties like ColorOrder are lost
  if opt.UseLocalColormap,
    fv.x(fv.x > opt.CLim(2)) = opt.CLim(2);
    fv.x(fv.x < opt.CLim(1)) = opt.CLim(1);
    image_localColormap(fv.x(:,ci)', opt.Colormap, 'CLim',opt.CLim);
  else
    H.image(jj)= image(fv.x(:,ci)', 'cDataMapping','scaled');
  end
  set(H.ax(jj), AxesStyle{:});
  ud= struct('type','ERP plus: bar', 'chan', str_vec2str(fv.clab(ci)));
  set(H.ax(jj), 'userData',ud);
  hold off;
  if strcmp(get(H.ax(jj), 'box'), 'on'),
    set(H.ax(jj), 'LineWidth',0.3);
    axis_redrawFrame(H.ax(jj));
  end
end
if diff(opt.CLim)==0, opt.CLim(2)= opt.CLim(2)+eps; end
set(H.ax, 'xLim',[0.5 size(fv.x,1)+0.5], 'xTick',[], 'yTick',[], ...
          'CLim',opt.CLim);

if opt.MoveBack,
  obj_moveBack(H.ax);
end

if ~isempty(opt.HScale),
  pos= get(opt.HScale.ax, 'position');
  dh= pos(4)*(1-opt.ScaleHeight)*opt.ScaleVPos;
  pos_cb= [pos(1)+(1-opt.ScaleWidth-opt.ScaleLeftShift)*pos(3) pos(2)+dh ...
           opt.ScaleWidth*pos(3) opt.ScaleHeight*pos(4)];
  H.scale.ax= axes('position', pos_cb);
  CLim= opt.CLim;
  colbar= linspace(CLim(1), CLim(2), size(opt.Colormap,1));
  if opt.UseLocalColormap,
    image_localColormap(colbar', opt.Colormap, 'CLim',opt.CLim);
  else
    H.scale.im= imagesc(1, colbar, [1:size(opt.Colormap,1)]');
  end
  axis_redrawFrame(H.scale.ax);
  if opt.AlphaStepsMode,
    yTick= 0:nValues;
    if opt.UseLocalColormap, yTick= yTick+1; end %% Just a hack...
    set(H.scale.ax, 'yTick',yTick, 'yTickLabel',100*[1 fv.alpha]);
  else
    ticks= visutil_goodContourValues(CLim(1), CLim(2), -3);
    tickLabels= util_trunc(ticks, opt.ScaleDigits);
    if opt.UseLocalColormap,
      YLim= get(gca,'YLim');
      ticks= (ticks-CLim(1))*diff(YLim)/diff(CLim)+YLim(1);
    end
    set(H.scale.ax, 'yTick',ticks, 'yTickLabel',tickLabels);
  end
  set(H.scale.ax, 'xTick',[], 'tickLength',[0 0], 'YDir','normal', ...
                  'FontSize',opt.ScaleFontSize);
  if ~isempty(opt.ScaleUnit),
    yLim= get(H.scale.ax, 'yLim');
    H.scale.unit= text(1, yLim(2), opt.ScaleUnit);
    set(H.scale.unit, 'horizontalAli','center', 'verticalAli','bottom');
  end
end

if nargout==0,
  clear H;
end
