function H= plot_scalpEvolutionPlusChannel(erp, mnt, clab, ival, varargin)
%SCALPEVOLUTIONPLUSCHANNEL - Display evolution of scalp topographies 
%
%Usage:
% H= plot_scalpEvolutionPlusChannel(ERP, MNT, CLAB, IVAL, <OPTS>)
%
% Makes an ERP plot in the upper panel with given interval marked,
% and draws below scalp topographies for all marked intervals,
% separately for each each Class. For each Classes topographies are
% plotted in one row and shared the same Color map scaling. (In future
% versions there might be different options for Color scaling.)
%
% IN: erp  - struct of epoched EEG data. For convenience used Classwise
%            averaged data, e.g., the result of proc_average.
%     mnt  - struct defining an electrode montage
%     clab - label of the channel(s) which are to be displayed in the
%            ERP plot.
%     ival - [nIvals x 2]-sized array of interval, which are marked in the
%            ERP plot and for which scalp topographies are drawn.
%            When all interval are consequtive, ival can also be a
%            vector of interval borders.
%     opts - struct or property/value list of optional fields/properties:
%      .IvalColor - [nColors x 3]-sized array of rgb-coded Colors
%                    with are used to mark intervals and corresponding 
%                    scalps. Colors are cycled, i.e., there need not be
%                    as many Colors as interval. Two are enough,
%                    default [0.4 1 1; 1 0.6 1].
%      .LegendPos - specifies the position of the legend in the ERP plot,
%                    default 0 (see help of legend for choices).
%      .PrintIvalUnits - appends the unit when writing the ival borders,
%                    default 1
%      the opts struct is passed to plot_scalpPattern
%
% OUT H - struct of handles to the created graphic objects.
%
%See also plot_scalpEvolution, plot_scalpPatternsPlusChannel, plot_scalp.

% Author(s): Benjamin Blankertz, Jan 2005

props= {'LineWidth',       3,                 'DOUBLE[1]';
        'IvalColor',       [.4 1 1; 1 .6 1],  'DOUBLE[- 3]';
        'XUnit',           '[ms]',            'CHAR';
        'YUnit',           '[\muV]',          'CHAR';
        'PrintIval',       0,                 'BOOL';
        'PrintIvalUnits',  1,                 'BOOL';
        'GlobalCLim',      0,                 'BOOL';
        'ScalePos',        'vert',            'CHAR';
        'ShrinkColorbar',  0,                 'DOUBLE';
        'PlotChannel',     1,                 'BOOL';
        'ChannelAtBottom', 0,                 'BOOL';
        'Subplot',         [],                'DOUBLE';
        'SubplotChannel',  [],                'DOUBLE';
        'FigureColor',     [1 1 1],           'DOUBLE[3]';
        'LegendPos',       'Best',            'CHAR'};

props_scalpPattern= plot_scalpPattern;
props_channel= plot_channel;

if nargin==0,
  H= opt_catProps(props, props_scalpPattern, props_channel);
  return
end

% With input argument erp, we know it better
if util_getDataDimension(erp)==1
  props_channel= plotutil_channel1D;
else
  props_channel= plotutil_channel2D;
end

opt= opt_proplistToStruct(varargin{:});
[opt, isdefault]= opt_setDefaults(opt, props);
opt_checkProplist(opt, props, props_scalpPattern, props_channel);

opt_scalpPattern= opt_substruct(opt, props_scalpPattern(:,1));
opt_channel= opt_substruct(opt, props_channel(:,1));

% fig_Visible = strcmp(get(gcf,'Visible'),'on'); % If figure is already inVisible jvm_* functions should not be called
% if fig_Visible
%   jvm= jvm_hideFig;
% end

if isfield(erp, 'XUnit'),
  [opt,isdefault]= opt_overrideIfDefault(opt, isdefault, ...
                                         'XUnit', erp.XUnit);
end

if isfield(erp, 'YUnit'),
  [opt,isdefault]= opt_overrideIfDefault(opt, isdefault, ...
                                         'YUnit', erp.YUnit);
end

if isfield(opt, 'ColorOrder'),
  if isequal(opt.ColorOrder,'rainbow'),
    nChans= size(erp.y,1);
    opt.ColorOrder= hsv2rgb([(0.5:nChans)'/nChans ones(nChans,1)*[1 0.85]]);
%  else
%    if size(opt.ColorOrder,1)<size(erp.y,1),
%      opt.ColorOrder= repmat(opt.ColorOrder, [size(erp.y,1) 1]);
%    end
  end
else
  opt.ColorOrder= get(gca, 'ColorOrder');
end

if max(sum(erp.y,2))>1,
  erp= proc_average(erp);
end

[AxesStyle, lineStyle]= opt_extractPlotStyles(opt);

if size(ival,1)==1,
  ival= [ival(1:end-1)', ival(2:end)'];
end
if any(ival(:)>erp.t(end)),
  warning('interval out of epoch range: truncating');
  ival= min(ival, erp.t(end));
end
if any(ival(:)<erp.t(1)),
  warning('interval out of epoch range: truncating');
  ival= max(ival, erp.t(1));
end

nIvals= size(ival,1);
nColors= size(opt.IvalColor,1);
nClasses= length(erp.className);

if isempty(opt.Subplot),
  clf;
end
set(gcf, 'Color',opt.FigureColor);

subplot_Offset= 0;
if opt.PlotChannel && ~isempty(clab),
  if ~isempty(opt.SubplotChannel),
    H.ax_erp= opt.SubplotChannel;
    axis_getQuitely(H.ax_erp);
  else
    if opt.ChannelAtBottom,
      H.ax_erp= subplotxl(1+nClasses, 1, 1+nClasses, ...
                          [0.1 0.05 0.1], [0.09 0 0.05]);
    else
      H.ax_erp= subplotxl(1+nClasses, 1, 1, 0.05, [0.09 0 0.05]);
      subplot_Offset= 1;
    end
  end
  if ~isempty(AxesStyle),
    set(H.ax_erp, AxesStyle{:});
  end
  hold on;   %% otherwise axis properties like ColorOrder are lost
  H.channel= plot_channel(erp, clab, opt_channel, 'Legend',0);
  for cc= 1:min(nColors,size(ival,1)),
    grid_markInterval(ival(cc:nColors:end,:), clab, opt.IvalColor(cc,:));
  end
  axis_redrawFrame(H.ax_erp);
  if ~isequal(opt.LegendPos, 'none'),
    if iscell(H.channel),
      hhh= H.channel{1};
    else
      hhh= H.channel;
    end
    % Check matlab version for downward compatability
    if str2double(strtok(version,'.'))<7
      H.leg= legend(hhh.plot, erp.className, opt.LegendPos);
    else
      % check if LegendPos is integer
      if isnumeric(opt.LegendPos)
        switch(opt.LegendPos)
          case -1, loc = 'NorthEastOutside';
          case 0,  loc = 'Best';
          case 1,  loc = 'NorthEast';
          case 2,  loc = 'NorthWest';
          case 3,  loc = 'SouthWest';
          case 4,  loc = 'SouthEast';
          otherwise, loc = 'Best';
        end
        warning('Location numbers are obsolete, use "%s" instead of "%d"', ...
          loc,opt.LegendPos);
      else
        loc = opt.LegendPos;
      end
      H.leg= legend(hhh.plot, erp.className, 'Location',loc);
    end
  end
end

%if ~isempty(opt.Subplot),
%  opt.Subplot= reshape(opt.Subplot, [nClasses, nIvals]);
%end
cb_per_ival= strcmp(opt.ScalePos, 'horiz');
for cc= 1:nClasses,
  if ~any(any(erp.x(:,:,cc))),
    bbci_warning('empty_Class', sprintf('Class %d is empty', cc));
    continue;
  end
  for ii= 1:nIvals,
    if any(isnan(ival(ii,:))),
      continue;
    end
    if ~isempty(opt.Subplot),
      axis_getQuitely(opt.Subplot(cc, ii));
    else
      subplotxl(nClasses+opt.PlotChannel, nIvals, ...
                ii+(cc-1+subplot_Offset)*nIvals, ...
                [0.01+0.08*cb_per_ival 0.03 0.05], [0.05 0.02 0.1]);
    end
    opt_scalpPattern= setfield(opt_scalpPattern, 'ScalePos','none');
    opt_scalpPattern= setfield(opt_scalpPattern, 'Class',cc);
    opt_scalpPattern.Linespec= {'linewidth',2, 'Color',opt.IvalColor(mod(ii-1,nColors)+1,:)};
    H.scalp(cc,ii)= plot_scalpPattern(erp, mnt, ival(ii,:), opt_scalpPattern);
    if cc==nClasses 
      if opt.PrintIval,
        yLim= get(gca, 'yLim');
        if opt.PrintIvalUnits==2,
          ival_str= sprintf('%s - %s\n%s', num2str(ival(ii,1)), num2str(ival(ii,2)), opt.XUnit);
        elseif opt.PrintIvalUnits==1,
          ival_str= sprintf('%s - %s %s', num2str(ival(ii,1)), num2str(ival(ii,2)), opt.XUnit);
        else
          ival_str= sprintf('%s - %s', num2str(ival(ii,1)), num2str(ival(ii,2)));
        end;
        H.text_ival(ii)= text(mean(xlim), yLim(1)-0.04*diff(yLim), ival_str, ...
                              'verticalAli','top', 'horizontalAli','center');
      end
      if cb_per_ival,
        H.cb(ii)= plotutil_colorbarAside('horiz');
        if ~opt.GlobalCLim,
%          visutil_unifyCLim([H.scalp(:,ii).ax], [zeros(1,nClasses-1) H.cb(ii)]);
          visutil_unifyCLim([H.scalp(:,ii).ax]);
        end
      end
    end
  end
  if strcmp(opt.ScalePos, 'vert'),
    H.cb(cc)= plotutil_colorbarAside;
    ylabel(H.cb(cc), opt.YUnit);
    if opt.ShrinkColorbar>0,
      cbpos= get(H.cb(cc), 'Position');
      cbpos(2)= cbpos(2) + cbpos(4)*opt.ShrinkColorbar/2;
      cbpos(4)= cbpos(4) - cbpos(4)*opt.ShrinkColorbar;
      set(H.cb(cc), 'Position',cbpos);
    end
    if ~opt.GlobalCLim,
%      visutil_unifyCLim([H.scalp(cc,:).ax], [zeros(1,nIvals-1) H.cb(cc)]);
      visutil_unifyCLim([H.scalp(cc,:).ax]);
    end
  end
  pos= get(H.scalp(cc,end).ax, 'position');
  yy= pos(2)+0.5*pos(4);
  H.background= fig_getBackgroundAxis;
  H.text(cc)= text(0.01, yy, erp.className{cc});
  set(H.text(cc), 'verticalAli','top', ...
                  'horizontalAli','center', ...
                  'rotation',90, ...
                  'Visible','on', ...
                  'FontSize',12, ...
                  'fontWeight','bold');
  if isfield(opt, 'ColorOrder'),
    ccc= 1+mod(cc-1, size(opt.ColorOrder,1));
    set(H.text(cc), 'Color',opt.ColorOrder(ccc,:));
  end
end
if opt.GlobalCLim,
%  ucb= [zeros(nClasses, nIvals-1) ones(nClasses,1)];
%  visutil_unifyCLim([H.scalp.ax], isfield(H, 'cb'));
  visutil_unifyCLim([H.scalp.ax]);
end

if nargout<1,
  clear H
end

% if fig_Visible
%   jvm_restoreFig(jvm);
% end
