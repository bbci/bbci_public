function H= plot_scalpPatternsPlusChannel(erp, mnt, clab, ival, varargin)
%PLOT_SCALPPATTERNSPLUSCHANNEL - Display Classwise topographies and one channel
%
%Synposis:
% H= plot_scalpPatternsPlusChannel(ERP, MNT, CLAB, IVAL, <OPTS>)
%
%Input:
% ERP:  struct of epoched EEG data
% MNT:  struct defining an electrode montage
% CLAB: label of the channel(s) which are to be displayed in the
%        ERP plot.
% IVAL: time interval for which scalp topographies are to be plotted.
%       May be either one interval for all Classes, or specific
%       intervals for each Class. In the latter case the k-th row of IVAL
%       defines the interval for the k-th Class.
% OPTS: struct or property/value list of optional fields/properties:
%  .LegendPos - specifies the position of the legend in the ERP plot,
%               default 'best' (see man page of legend for choices).
%  .MarkIval  - When true, the time interval is marked in the channel plot.
%
%The opts struct is passed to plot_scalpPattern
%
%Output:
% H: Handle to several graphical objects
%
%See also plot_scalpPatterns, plot_scalpEvolutionPlusChannel, plot_scalp.

% Author(s): Benjamin Blankertz, Jan 2005

props = {'LineWidth',           3,                  'DOUBLE';
         'IvalColor',           0.85*[1 1 1],       'DOUBLE[3]';
         'ColorOrder',          [0 0 0],            'DOUBLE[3]';
         'MarkIval',            0,                  'BOOL';
         'XGrid',               'on',               'CHAR';
         'YGrid',               'on',               'CHAR';
         'XUnit',               '[ms]',             'CHAR';
         'PlotChannel',         1,                  'BOOL';
         'ScalePos',            'vert',             'CHAR';
         'LegendPos',           'best',             'CHAR';
         'NewColormap',         0,                  'BOOL';
         'MarkPatterns',        [],                 'DOUBLE|CHAR';
         'MarkStyle',           {'LineWidth',3},    'CELL';
         'Subplot',             [],                 'DOUBLE'};

props_scalpPattern= plot_scalpPattern;
props_channel= plotutil_channel1D;

if nargin==0,
  H= opt_catProps(props, props_scalpPattern, props_channel); return
end

opt= opt_proplistToStruct(varargin{:});
[opt,isdefault]= opt_setDefaults(opt, props);
opt_checkProplist(opt, props, props_scalpPattern, props_channel);
[opt,isdefault] = opt_overrideIfDefault(opt,isdefault, 'MarkIval',size(ival,1)==1,'PlotChannel',~isempty(clab));


opt_scalpPattern= opt_substruct(opt, props_scalpPattern(:,1));
opt_channel= opt_substruct(opt, props_channel(:,1));

misc_checkType(erp,'!STRUCT(x y className)');
misc_checkType(mnt,'!STRUCT(x)');

if nargin<4 || isempty(ival),
  ival= [NaN NaN]; %erp.t([1 end]);
elseif size(ival,2)==1,
  ival= [ival ival];
elseif size(ival,2)>2,
  error('IVAL must be sized [N 2]');
end

if isfield(erp, 'XUnit'),
  [opt,isdefault]= opt_overrideIfDefault(opt, isdefault, 'XUnit', erp.xUnit);
end

if max(sum(erp.y,2))>1,
  erp= proc_average(erp);
end
nClasses= length(erp.className);

% Diese Abfrage ist nicht korrekt, da alle Felder schon gesetzt sein
% muessen
if ~isfield(opt, 'CLim') && all(erp.x>=0),
  opt.CLim= 'range';
  warning('automatically set opt.CLim= ''range''.');
end

if ischar(opt.MarkPatterns),
  if ~strcmpi(opt.MarkPatterns, 'all'),
    warning('unknown value for opt.MarkPatterns ignored');
  end
  opt.MarkPatterns= 1:nPat;
end

[AxesStyle, lineStyle]= opt_extractPlotStyles(opt);
nIvals= size(ival,1);
if nIvals<nClasses,
  ival= repmat(ival, [nClasses, 1]);
end

if opt.NewColormap,
  acm= visutil_addColormap(opt.Colormap);
end
if isempty(opt.Subplot),
  clf;
end
for cc= 1:nClasses,
  if isempty(opt.Subplot),
    subplotxl(1, nClasses+opt.PlotChannel, cc+opt.PlotChannel, ...
              0.07, [0.07 0.02 0.1]);
  else
    axis_getQuietly(opt.Subplot(cc));
  end
  opt_scalpPattern= setfield(opt_scalpPattern, 'ScalePos','none');
  if opt.NewColormap,
    opt_scalpPattern= rmfield(opt_scalpPattern, 'Colormap');
    opt_scalpPattern= setfield(opt_scalpPattern, 'NewColormap',0);
  end
  opt_scalpPattern.Class= cc;
  clscol= opt.ColorOrder(min(cc,size(opt.ColorOrder,1)),:);
  opt_scalpPattern= opt_setDefaults(opt_scalpPattern, 'Linespec', {'linewidth',2, 'Color',clscol});
  h.H_topo(cc)= plot_scalpPattern(erp, mnt, ival(cc,:), opt_scalpPattern);
  if ismember(cc, opt.MarkPatterns,'legacy'),
    set([h.H_topo(cc).head h.H_topo(cc).nose], opt.MarkStyle{:});
  end
  yLim= get(gca, 'yLim');
  h.text(cc)= text(mean(xlim), yLim(2)+0.06*diff(yLim), erp.className{cc});
  set(h.text(cc), 'Color',clscol);
  if ~any(isnan(ival(cc,:))),
    ival_str= sprintf('%g - %g %s', ival(cc,:), opt.XUnit);
  else
    ival_str= '';
  end
  h.text_ival(cc)= text(mean(xlim), yLim(1)-0.04*diff(yLim), ival_str);
%  axis_aspectRatioToPosition;   %% makes Colorbar appear in correct size
end
set(h.text, 'horizontalAli','center', ...
            'Visible','on', ...
            'FontSize',12, 'fontWeight','bold');
set(h.text_ival, 'verticalAli','top', 'horizontalAli','center', ...
                 'Visible','on');  
if ismember(opt.ScalePos, {'horiz','vert'},'legacy'),
  h.cb= plotutil_colorbarAside(opt.ScalePos);
  % hack to fix a matlab bug
  ud= get(h.cb, 'UserData');
  ud.orientation= opt.ScalePos;
  set(h.cb, 'UserData',ud);
  % put YUnit on top of Colorbar
  if isfield(erp, 'yUnit'),
    axes(h.cb);
    yl= get(h.cb, 'YLim');
    h.YUnit= text(mean(xlim), yl(2), erp.yUnit);
    set(h.YUnit, 'horizontalAli','center', 'verticalAli','bottom');
  end
  if nClasses>1,
%    visutil_unifyCLim([h.H_topo.ax], [zeros(1,nClasses-1) h.cb]);
    visutil_unifyCLim([h.H_topo.ax]);
  end
elseif nClasses>1,
  visutil_unifyCLim([h.H_topo.ax], [zeros(1,nClasses)]);
end
if opt.NewColormap,
  visutil_acmAdaptCLim(acm, [h.H_topo.ax]);
end

if opt.PlotChannel,
  if isempty(opt.Subplot),
    h.ax_erp= subplotxl(1, nClasses+1, 1, 0.1, [0.06 0.02 0.1]);
  else
    h.ax_erp= opt.Subplot(nClasses+1);
    axes(h.ax_erp);
  end
  topopos= get(h.H_topo(end).ax, 'position');
  pos= get(h.ax_erp, 'position');
  pos([2 4])= topopos([2 4]);
  set(h.ax_erp, 'position',pos);
  if ~isempty(AxesStyle),
    set(h.ax_erp, AxesStyle{:});
  end
  hold on;   %% otherwise axis properties like ColorOrder are lost
  H.channel= plot_channel(erp, clab, opt_channel, 'legend',0);
  if opt.MarkIval,
    for cc= 1:nIvals,
      grid_markInterval(ival(cc,:), clab, ...
                    opt.IvalColor(min(cc,size(opt.IvalColor,1)),:));
    end
    axis_redrawFrame(h.ax_erp);
  end
  set(get(h.ax_erp, 'title'), 'FontSize',12, 'fontWeight','bold');
  if ~isequal(opt.LegendPos, 'none'),
    h.leg= legend(erp.className, 'Location',opt.LegendPos);
  end
end

if nargout<1,
  clear h
end
