function H= grid_plot(epo, mnt, varargin)
%GRID_PLOT - Classwise averaged epochs in a grid layout
%
%Synopsis:
% H= grid_plot(EPO, MNT, <OPT>)
%
%Input:
% EPO: struct of epoched signals, see makeSegments
% MNT: struct for electrode montage, see setElectrodeMontage
% OPT: property/value list or struct of options with fields/properties:
%  .ScaleGroup -  groups of channels, where each group should
%                 get the same y limits, cell array of cells,
%                 default {util_scalpChannels, {'EMG*'},{'EOGh'},{'EOGv'}};
%                 As group you can also use util_scalpChannels (without
%                  quotes!) or 'all' (with quotes!).
%  .ScalePolicy - says how the y limits are chosen:
%                 'auto': choose automatically,
%                 'sym': automatically but symmetric around 0
%                 'individual': choose automatically y limits individual
%                 for each channel
%                 'individual_sym': choose automatically y limits
%                 individual for each channel, but symmetric around 0
%                 'individual_tight': choose automatically y limits
%                 individual for each channel, but tight limits
%                 [lower upper]: define y limits;
%                 .scapePolicy is usually a cell array, where
%                 each cell corresponds to one .ScaleGroup. Otherwise it
%                 applies only to the first group (util_scalpChannels by
%                 defaults)
%  .ScaleUpperLimit - values (in magnitude) above this limit are not 
%                     considered, when choosing the y limits, default inf
%  .ScaleLowerLimit - values (in magnitude) below this limit are not 
%                     considered, when choosing the y limits, default 0
%  .TitleDir    - direction of figure title, 'horizontal' (default),
%                 'vertical', 'none'
%
%   * The following properties of OPT are passed to plot_channel:
%  .XUnit       - unit of x axis, default 'ms'
%  .YUnit       - unit of y axis, default epo.unit if this field
%                 exists, 'a.u.' otherwise
%  .YDir        - 'normal' (negative down) or 'reverse' (negative up)
%  .RefCol      - Color of patch indicating the baseline interval
%  .ColorOrder  - defines the Colors for drawing the curves of the
%                 different Classes. if not given the ColorOrder
%                 of the current axis is taken. as special gimmick
%                 you can use 'rainbow' as ColorOrder.
%  .XGrid, ...  - many axis properties can be used in the usual
%                 way
%  .XZeroLine   - if true, draw an axis along the x-axis at y=0
%  .YZeroLine   - if true, draw an axis along the y-axis at x=0
%  .ZeroLine*   - with * in {'Color','Style'} selects the
%                 drawing style of the axes at x=0/y=0
%  .AxisTitle*  - with * in {'Color', 'HorizontalAlignment',
%                 'VerticalAlignment', 'FontWeight', 'FontSize'}
%                 selects the appearance of the subplot titles.
%
%Output:
%   H - handle to graphic objects
%
% SEE  makeEpochs, setDisplayMontage, plot_channel, grid_*

% Author(s): Benjamin Blankertz, Feb 2003 & Mar 2005

props= {'Axes',                           [],                     'DOUBLE';
        'AxisTitleHorizontalAlignment',   'center',               'CHAR';
        'AxisTitleVerticalAlignment',     'top',                  'CHAR';
        'AxisTitleColor',                 'k',                    'CHAR[1]|DOUBLE[3]';
        'AxisTitleFontSize',              get(gca,'FontSize'),    'DOUBLE'
        'AxisTitleFontWeight',            'normal',               'CHAR';
        'AxisTitleLayout',                'oneline',              'CHAR';
        'AxisType',                       'box',                  'CHAR';
        'Box',                            'on',                   'CHAR';
        'FigureColor',                    [0.8 0.8 0.8],          'DOUBLE[3]';
        'GridOverPatches',                1,                      'BOOL';
        'HeadMode',                       0,                      'BOOL';
        'HeadModeSpec',                   {'LineProperties',{'LineWidth',5, 'Color',0.7*[1 1 1]}},     'STRUCT|CELL';
        'LegendVerticalAlignment',        'middle',               'CHAR';
        'OversizePlot',                   1,                      'BOOL';
        'PlotStd',                        0,                      'BOOL'
        'ScaleGroup'                      [],                     'CHAR|CELL';
        'ScalePolicy',                    'auto',                 'CHAR|DOUBLE[2]';
        'ScaleUpperLimit',                inf,                    'DOUBLE';
        'ScaleLowerLimit',                0,                      'DOUBLE';
        'ScaleShowOrientation',           1,                      'BOOL';
        'ShiftAxesUp',                    [],                     'DOUBLE';
        'ShrinkAxes',                     [1 1],                  'DOUBLE[1-2]';
        'TightenBorder',                  0.03,                   'DOUBLE';
        'TitleDir',                       'horizontal',           'CHAR';
        'TitleAppendix',                  '',                     'CHAR';
        'XTickAxes',                      '*',                    'CHAR';
        'XUnit',                          'ms',                   'CHAR';
%        'YUnit',                          'a.u.',                 'CHAR';
        'YUnit',                          '\muV',                 'CHAR';
        'YDir',                           'normal',               'CHAR';
        'YLim',                           [],                     'DOUBLE[2]';
        };

props_channel = plot_channel;
props_addScale = gridutil_addScale;

if nargin==0,
  H= opt_catProps(props, props_channel, props_addScale);
  return
end

opt= opt_proplistToStruct(varargin{:});
[opt, isdefault]= opt_setDefaults(opt, props);
opt_checkProplist(opt, props, props_channel, props_addScale);

if nargin<2 || isempty(mnt),
  mnt= struct('clab',{epo.clab});
else
  mnt= mnt_adaptMontage(mnt, epo);
end

if strcmpi(opt.AxisType, 'cross'),  %% other default values for 'cross'
  opt= opt_overrideIfDefault(opt, isdefault, ...
                             'Box', 'off', ...
                             'GridOverPatches', 0, ...
                             'ShrinkAxes', [0.9 0.9], ...
                             'AxisTitleVerticalAlignment', 'cap');
%                             'OversizePlot', 1.5, ...
end
if opt.OversizePlot>1,
  [opt, isdefault]= ...
      opt_overrideIfDefault(opt, isdefault, ...
                            'Visible', 'off');
end
if isfield(opt, 'XTick'),
  [opt, isdefault]= ...
      opt_overrideIfDefault(opt, isdefault, ...
                            'ShrinkAxes', 0.8);
end
if isdefault.ShiftAxesUp && ...
      (isfield(opt, 'XTick') && ~isempty(opt.xTick)), ...
      opt.ShiftAxesUp= 0.05;
end
if isdefault.XUnit && isfield(epo, 'xUnit'),
  opt.XUnit= epo.xUnit;
end
if isdefault.YUnit && isfield(epo, 'yUnit'),
  opt.YUnit= epo.yUnit;
elseif isdefault.YUnit && isfield(epo, 'cnt_info') && ...
        isfield(epo.cnt_info, 'yUnit'),
  opt.YUnit= epo.cnt_info.yUnit;
end
if ~isempty(opt.YLim),
  if ~isdefault.ScalePolicy,
    warning('opt.YLim overrides opt.ScalePolicy');
  end
  opt.ScalePolicy= {opt.YLim};
  isdefault.ScalePolicy= 0;
end
if ~iscell(opt.ScalePolicy),
  opt.ScalePolicy= {opt.ScalePolicy};
end
if isempty(opt.ScaleGroup),
  [grd_clab, grd_clab_idx]= gridutil_getClabOfGrid(mnt);
  if strncmp(opt.ScalePolicy, 'individual', length('individual')),
    opt.ScaleGroup= grd_clab;
    pol= opt.ScalePolicy(length('individual')+1:end);
    if isempty(pol),
      pol= 'auto';
    else
      if pol(1)=='_', pol(1)=[]; end
    end
    opt.ScalePolicy= repmat({pol}, size(grd_clab));
  else
    scalp_idx= util_scalpChannels(epo);
    if isempty(scalp_idx),
      opt.ScaleGroup= {intersect(grd_clab, epo.clab)};
    else
      scalp_idx= intersect(scalp_idx, util_chanind(epo, grd_clab));
      emgeog_idx= util_chanind(epo, 'EOGh','EOGv','EMG*');
      others_idx= setdiff(1:length(epo.clab), [scalp_idx emgeog_idx]);
      opt.ScaleGroup= {epo.clab(scalp_idx), {'EMG*'}, {'EOGh'}, {'EOGv'}, ...
                       epo.clab(others_idx)};
      def_ScalePolicy= {'auto', [-5 50], 'sym', 'auto', 'auto'};
      def_AxisTitleLayout= {'oneline', 'twolines', 'twolines', 'twolines', ...
                    'twolines'};
      if isdefault.ScalePolicy,
        opt.ScalePolicy= def_ScalePolicy;
      else
        memo= opt.ScalePolicy;
        opt.ScalePolicy= def_ScalePolicy;
        opt.ScalePolicy(1:length(memo))= memo;
      end
      if isdefault.AxisTitleLayout,
        opt.AxisTitleLayout= def_AxisTitleLayout;
      end
    end
  end
elseif isequal(opt.ScaleGroup, 'all'),
  opt.ScaleGroup= {gridutil_getClabOfGrid(mnt)};
elseif ~iscell(opt.ScaleGroup),
  opt.ScaleGroup= {opt.ScaleGroup};
end
if length(opt.ScalePolicy)==1 && length(opt.ScaleGroup)>1,
  opt.ScalePolicy= repmat(opt.ScalePolicy, 1, length(opt.ScaleGroup));
end
if ~iscell(opt.AxisTitleLayout),
  opt.AxisTitleLayout= {opt.AxisTitleLayout};
end
if length(opt.AxisTitleLayout)==1 && length(opt.ScaleGroup)>1,
  opt.AxisTitleLayout= repmat(opt.AxisTitleLayout, 1, length(opt.ScaleGroup));
end

if length(opt.ShrinkAxes)==1,
  opt.ShrinkAxes= [1 opt.ShrinkAxes];
end

opt_channel= opt_substruct(opt, props_channel(:,1));
opt_addScale = opt_substruct(opt, props_addScale(:,1));

if isfield(mnt, 'box'),
  mnt.box_sz(1,:)= mnt.box_sz(1,:) * opt.ShrinkAxes(1);
  mnt.box_sz(2,:)= mnt.box_sz(2,:) * opt.ShrinkAxes(2) * opt.OversizePlot;
  if isfield(mnt, 'scale_box_sz'),
   mnt.scale_box_sz(1)= mnt.scale_box_sz(1)*opt.ShrinkAxes(1);
   mnt.scale_box_sz(2)= mnt.scale_box_sz(2)*opt.ShrinkAxes(2)*opt.OversizePlot;
  end
end

if max(sum(epo.y,2))>1,
  epo= proc_average(epo, 'Std',opt.PlotStd);
end

if isempty(opt.Axes),
  clf;
end
set(gcf, 'Color',opt.FigureColor);

DisplayChannels= find(ismember(strtok(mnt.clab), strtok(epo.clab),'legacy'));
if isfield(mnt, 'box'),
  DisplayChannels= intersect(DisplayChannels, grd_clab_idx);
end
nDisps= length(DisplayChannels);
% may be 'C3' while the latter is 'C3 lap'
idx= util_chanind(epo, mnt.clab(DisplayChannels));
axestitle= epo.clab(idx);

yLim= zeros(length(opt.ScaleGroup), 2);
for ig= 1:length(opt.ScaleGroup),
  ax_idx= util_chanind(mnt.clab(DisplayChannels), opt.ScaleGroup{ig});
  if isempty(ax_idx), continue; end
  ch_idx= util_chanind(epo, mnt.clab(DisplayChannels(ax_idx)));
  if isnumeric(opt.ScalePolicy{ig}),
    yLim(ig,:)= opt.ScalePolicy{ig};
  else
    dd= epo.x(:,ch_idx,:);
    idx= find(abs(dd(:))<opt.ScaleUpperLimit & ...
              abs(dd(:))>=opt.ScaleLowerLimit);
    yl= [nanmin(dd(idx)) nanmax(dd(idx))];
    % add border not to make it too tight:
    yl= yl + [-1 1]*opt.TightenBorder*diff(yl);
    if strncmp(opt.ScalePolicy{ig},'tight',5),
      yLim(ig,:)= yl;
    else
      % determine nicer limits
      dig= floor(log10(diff(yl)));
      if diff(yl)>1,
        dig= max(1, dig);
      end
      yLim(ig,:)= [util_trunc(yl(1),-dig+1,'floor') util_trunc(yl(2),-dig+1,'ceil')];
    end
  end
  if ~isempty(strfind(opt.ScalePolicy{ig},'sym')),
    yl= max(abs(yLim(ig,:)));
    yLim(ig,:)= [-yl yl];
  end
  if any(isnan(yLim(ig,:))),
    yLim(ig,:)= [-1 1];
  end
  if ig==1 && length(ax_idx)>1,
    ch2group= ones(1,nDisps);
  else
    ch2group(ax_idx)= ig;
    for ia= ax_idx,
      if max(abs(yLim(ig,:)))>=100,
        dig= 0;
      elseif max(abs(yLim(ig,:)))>=1,
        dig= 1;
      else
        dig= 2;
      end
      switch(opt.AxisTitleLayout{ig}),
       case 'oneline',
        axestitle{ia}= sprintf('%s  [%g %g] %s', ...
                               axestitle{ia}, ...
                               util_trunc(yLim(ig,:), dig), opt.YUnit);
       case 'nounit',
        axestitle{ia}= sprintf('%s  [%g %g]', ...
                               axestitle{ia}, ...
                               util_trunc(yLim(ig,:), dig));
       case 'twolines',
        axestitle{ia}= sprintf('%s\n[%g %g] %s', ...
                               axestitle{ia}, ...
                               util_trunc(yLim(ig,:), dig), opt.YUnit);
       case 'twolines_nounit',
        axestitle{ia}= sprintf('%s\n[%g %g]', ...
                               axestitle{ia}, ...
                               util_trunc(yLim(ig,:), dig));
       otherwise,
        error('invalid choice for opt.AxisTitleLayout');
      end
    end
  end
end

H.ax= zeros(1, nDisps);
opt_plot= {'Legend',1, 'Title','', 'UnitDispPolicy','none', ...
           'GridOverPatches',0};
if isfield(mnt, 'box') && isnan(mnt.box(1,end))
  % no grid position for legend available
  opt_plot{2}= 0;
end

for ia= 1:nDisps,
  ic= DisplayChannels(ia);
  if ~isempty(opt.Axes),
    H.ax(ia)= opt.Axes(ic);
    axis_getQuietly(H.ax(ia));
  else
    H.ax(ia)= axis_getQuietly('position', gridutil_getAxisPos(mnt, ic));
  end
  cchan = plot_channel(epo, mnt.clab{ic}, opt_channel, opt_plot{:}, ...
                          'YLim', yLim(ch2group(ia),:), ...
                          'AxisTitle', axestitle{ia}, 'Title',0, ...
                          'SmallSetup',1);
  cchan.clab = mnt.clab{ic};
  H.chan(ia) = cchan;
  if ic==DisplayChannels(1),
    opt_plot{2}= 0;
    H.leg= H.chan(ia).leg;
    leg_pos= gridutil_getAxisPos(mnt, 0);
    if ~any(util_isnan(leg_pos)) && ~util_isnan(H.leg),
      leg_pos_orig= get(H.leg, 'position');
      if leg_pos(4)>leg_pos_orig(4),
        switch(lower(opt.LegendVerticalAlignment)), 
          case 'top',
           leg_pos(2)= leg_pos(2)-leg_pos_orig(4)+leg_pos(4);
         case 'middle',
           leg_pos(2)= leg_pos(2)+(leg_pos(4)-leg_pos_orig(4))/2;
        end
      end
      leg_pos(3:4)= leg_pos_orig(3:4);  %% use original size
      set(H.leg, 'position', leg_pos);
      ud= get(H.leg, 'userData');
      ud= opt_setDefaults(ud, {'type','ERP plus'; 'chan','legend'});
      set(H.leg, 'userData',ud);
      if exist('verLessThan')~=2 || verLessThan('matlab','7'),
        set(H.leg, 'Visible','off');
        set(get(H.leg,'children'), 'Visible','on');
      end
    end
  end
end

if isfield(mnt, 'scale_box') && all(~isnan(mnt.scale_box)),
  ax_idx= util_chanind(mnt.clab(DisplayChannels), opt.ScaleGroup{1});
  set(gcf,'CurrentAxes',H.ax(ax_idx(1)))
  H.scale= gridutil_addScale(mnt, opt_addScale);
end
if opt.GridOverPatches,
  plotutil_gridOverPatches('Axes',H.ax);
end

if ~isdefault.XTickAxes,
  h_xta= H.ax(util_chanind(mnt.clab(DisplayChannels), opt.XTickAxes));
  set(setdiff(H.ax, h_xta,'legacy'), 'XTickLabel','');
end

if ~strcmp(opt.TitleDir, 'none'),
  tit= '';
  if isfield(opt, 'Title'),
    tit= [opt.Title ':  '];
  elseif isfield(epo, 'title'),
    tit= [util_untex(epo.title) ':  '];
  end
  if isfield(epo, 'className'),
    tit= [tit, str_vec2str(epo.className, [], ' / ') ', '];
  end
  if isfield(epo, 'N'),
    tit= [tit, 'N= ' str_vec2str(epo.N,[],'/') ', '];
  end
  if isfield(epo, 't'),
    tit= [tit, sprintf('[%g %g] %s, ', util_trunc(epo.t([1 end])), opt.XUnit)];
  end
  tit= [tit sprintf('[%g %g] %s', util_trunc(yLim(1,:)), opt.YUnit)];
  if strcmpi(opt.YDir, 'reverse'),
    tit= [tit ' neg. up'];
  end
  if ~isempty(opt.TitleAppendix),
    tit= [tit ', ' opt.TitleAppendix];
  end
  H.title= visutil_addTitle(tit, opt.TitleDir);
end

if ~isempty(opt.ShiftAxesUp) && opt.ShiftAxesUp~=0,
  gridutil_shiftAxesUp(opt.ShiftAxesUp);
end

if opt.HeadMode,
  delete(H.title);
  H.title= [];
  set([H.chan.ax_title], 'Visible','on');
  set_backgroundaxis;
  H.scalpOutline= plot_scalpOutline(mnt, opt.HeadModeSpec{:}, 'DrawEars', 1);
  set(H.scalpOutline.ax, 'Visible','off');
  delete(H.scalpOutline.label_markers);
  obj_moveBack(H.scalpOutline.ax);
end

if nargout==0,
  clear H;
end
