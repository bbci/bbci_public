function H= grid_imagesc(epo, mnt, varargin)
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
%                 default {get_scalpChannels, {'EMG*'},{'EOGh'},{'EOGv'}};
%                 As group you can also use get_scalpChannels (without quotes!)
%                 or 'all' (with quotes!).
%  .ScalePolicy - says how the y limits are chosen:
%                 'auto': choose automatically,
%                 'sym': automatically but symmetric around 0
%                 'individual': choose automatically y limits individual
%                    for each channel
%                 'individual_sym': choose automatically y limits individual
%                    for each channel, but symmetric around 0
%                 'individual_tight': choose automatically y limits individual
%                    for each channel, but tight limits
%                 [lower upper]: define y limits;
%                 .scapePolicy is usually a cell array, where
%                 each cell corresponds to one .ScaleGroup. Otherwise it
%                 applies only to the first group (get_scalpChannels by defaults).
%  .ScaleUpperLimit - values (in magnitude) above this limit are not 
%                 considered, when choosing the y limits, default inf
%  .ScaleLowerLimit - values (in magnitude) below this limit are not 
%                 considered, when choosing the y limits, default 0
%  .TitleDir    - direction of figure title,
%                 'horizontal' (default), 'vertical', 'none'
%
%    * The following properties of OPT are passed to plot_channel:
%  .XUnit  - unit of x axis, default 'ms'
%  .YUnit  - unit of y axis, default epo.unit if this field
%            exists, '\muV' otherwise
%  .YDir   - 'normal' (negative down) or 'reverse' (negative up)
%  .RefCol - Color of patch indicating the baseline interval
%  .ColorOrder -  defines the Colors for drawing the curves of the
%                 different Classes. if not given the ColorOrder
%                 of the current axis is taken. as special gimmick
%                 you can use 'rainbow' as ColorOrder.
%  .XGrid, ... -  many axis properties can be used in the usual
%                 way
%  .XZeroLine   - if true, draw an axis along the x-axis at y=0
%  .YZeroLine   - if true, draw an axis along the y-axis at x=0
%  .ZeroLine*   - with * in {'Color','Style'} selects the
%                 drawing style of the axes at x=0/y=0
%  .AxisTitle*  - with * in {'Color', 'HorizontalAlignment',
%                 'VerticalAlignment', 'FontWeight', 'FontSize'}
%                 selects the appearance of the subplot titles.
%
% SEE  makeEpochs, setDisplayMontage, plot_channel, grid_*

% Author(s): Benjamin Blankertz, Feb 2003 & Mar 2005

props = {'YDir',                            'normal',               'CHAR';
         'XUnit',                           'ms',                   'CHAR';
         'YUnit',                           'Hz',                   'CHAR';
         'CUnit',                           'r^2',                  'CHAR';
         'TightenBorder',                   .03,                    'DOUBLE';
         'AxisType',                        'box',                  'CHAR';
         'Box',                             'on',                   'CHAR';
         'ShiftAxesUp',                     [],                     'DOUBLE';
         'ShrinkAxes',                      [1 1],                  'DOUBLE[1-2]';
         'OversizePlot',                    1,                      'BOOL';
         'ScalePolicy',                     'auto',                 'CHAR';
         'ScaleUpperLimit',                 inf,                    'DOUBLE';
         'ScaleLowerLimit',                 0,                      'DOUBLE';
         'LegendVerticalAlignment',         'middle',               'CHAR';
         'FigureColor',                     [0.8 0.8 0.8],          'DOUBLE[3]';
         'TitleDir',                        'horizontal',           'CHAR';
         'AxisTitleHorizontalAlignment',    'center',               'CHAR';
         'AxisTitleVerticalAlignment',      'top',                  'CHAR';
         'AxisTitleColor',                  'k',                    'CHAR[1]|DOUBLE[3]';
         'AxisTitleFontSize',               get(gca,'FontSize'),    'DOUBLE';
         'AxisTitleFontWeight',             'normal',               'CHAR';
         'ScaleShowOrientation',            1,                      'BOOL';
         'PlotStd',                         0,                      'BOOL'};

props_channel = plot_channel2D;

if nargin==0,
  H= opt_catProps(props, props_channel);
  return
end

opt= opt_proplistToStruct(varargin{:});
[opt, isdefault]= opt_setDefaults(opt, props);

opt_checkProplist(opt, props, props_channel);

opt_channel= opt_substruct(opt, props_channel(:,1));

s = size(epo.x);

if nargin<2 | isempty(mnt),
  mnt= strukt('clab',epo.clab);
else
  mnt= mnt_adaptMontage(mnt, epo);
end
%  
%  if strcmpi(opt.AxisType, 'cross'),  %% other default values for 'cross'
%    opt= opt_overrideIfDefault(opt, isdefault, ...
%                               'Box', 'off', ...
%                               'ShrinkAxes', [0.9 0.9], ...
%                               'AxisTitleVerticalAlignment', 'cap');
%  %                             'OversizePlot', 1.5, ...
%  end
if opt.OversizePlot>1,
  [opt, isdefault]= ...
      opt_overrideIfDefault(opt, isdefault, ...
                            'Visible', 'off');
end
%  if isfield(opt, 'xTick'),
%    [opt, isdefault]= ...
%        opt_overrideIfDefault(opt, isdefault, ...
%                              'ShrinkAxes', 0.8);
%  end
if isdefault.shift_axesUp & ...
      (isfield(opt, 'xTick') & ~isempty(opt.xTick)), ...
      opt.ShiftAxesUp= 0.05;
end
%  if isdefault.XUnit & isfield(epo, 'XUnit'),
%    opt.XUnit= epo.XUnit;
%  end
%  if isdefault.YUnit & isfield(epo, 'YUnit'),
%    opt.YUnit= epo.YUnit;
%  end
%  if isfield(opt, 'yLim'),
%    if ~isdefault.ScalePolicy,
%      warning('opt.yLim overrides opt.ScalePolicy');
%    end
%    opt.ScalePolicy= {opt.yLim};
%    isdefault.ScalePolicy= 0;
%  end
if ~iscell(opt.ScalePolicy),
  opt.ScalePolicy= {opt.ScalePolicy};
end
if ~isfield(opt, 'ScaleGroup'),
  grd_clab= get_clabOfGrid(mnt);
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
    scalp_idx= get_scalpChannels(epo);
    if isempty(scalp_idx),
      opt.ScaleGroup= {intersect(grd_clab, epo.clab)};
    else
      scalp_idx= intersect(scalp_idx, util_chanind(epo, grd_clab));
      emgeog_idx= util_chanind(epo, 'EOGh','EOGv','EMG*');
      others_idx= setdiff(1:length(epo.clab), [scalp_idx emgeog_idx]);
      opt.ScaleGroup= {epo.clab(scalp_idx), {'EMG*'}, {'EOGh'}, {'EOGv'}, ...
                       epo.clab(others_idx)};
      def_ScalePolicy= {'auto', [-5 50], 'sym', 'auto', 'auto'};
      if isdefault.ScalePolicy,
        opt.ScalePolicy= def_ScalePolicy;
      else
        memo= opt.ScalePolicy;
        opt.ScalePolicy= def_ScalePolicy;
        opt.ScalePolicy(1:length(memo))= memo;
      end
    end
  end
elseif isequal(opt.ScaleGroup, 'all'),
  opt.ScaleGroup= {get_clabOfGrid(mnt)};
elseif ~iscell(opt.ScaleGroup),
  opt.ScaleGroup= {opt.ScaleGroup};
end

if length(opt.ScalePolicy)==1 & length(opt.ScaleGroup)>1,
  opt.ScalePolicy= repmat(opt.ScalePolicy, 1, length(opt.ScaleGroup));
end
if length(opt.ShrinkAxes)==1,
  opt.ShrinkAxes= [1 opt.ShrinkAxes];
end

if isfield(mnt, 'box'),
  mnt.box_sz(1,:)= mnt.box_sz(1,:) * opt.ShrinkAxes(1);
  mnt.box_sz(2,:)= mnt.box_sz(2,:) * opt.ShrinkAxes(2) * opt.OversizePlot;
  if isfield(mnt, 'scale_box_sz'),
   mnt.scale_box_sz(1)= mnt.scale_box_sz(1)*opt.ShrinkAxes(1);
   mnt.scale_box_sz(2)= mnt.scale_box_sz(2)*opt.ShrinkAxes(2)*opt.OversizePlot;
  end
end

%  if max(sum(epo.y,2))>1,
%    epo= proc_average(epo, 'std',opt.PlotStd);
%  end

%  set(gcf, 'Color',opt.FigureColor);

DisplayChannels= find(ismember(strtok(mnt.clab), strtok(epo.clab)));
%  if isfield(mnt, 'box'),
%    DisplayChannels= intersect(DisplayChannels, find(~isnan(mnt.box(1,1:end-1))));
%  end
nDisps= length(DisplayChannels);
%% mnt.clab{DisplayChannels(ii)} may differ from epo.clab{ii}, e.g. the former
%% may be 'C3' while the latter is 'C3 lap'
idx= util_chanind(epo, mnt.clab(DisplayChannels));
Axestitle= apply_cellwise(epo.clab(idx), 'sprintf');

%w_cm= warning('query', 'bci:missing_channels');
%warning('off', 'bci:missing_channels');
%all_idx= 1:length(mnt.clab);
%  yLim= zeros(length(opt.ScaleGroup), 2);
%  for ig= 1:length(opt.ScaleGroup),
%    ax_idx= util_chanind(mnt.clab(DisplayChannels), opt.ScaleGroup{ig});
%    if isempty(ax_idx), continue; end
%  %  ch_idx= find(ismember(all_idx, ax_idx));
%    ch_idx= DisplayChannels(ax_idx);
%    if isnumeric(opt.ScalePolicy{ig}),
%      yLim(ig,:)= opt.ScalePolicy{ig};
%    else
%      dd= epo.x(:,ch_idx,:);
%  %    idx= find(~isinf(dd(:)));
%      idx= find(abs(dd(:))<opt.ScaleUpperLimit & ...
%                abs(dd(:))>=opt.ScaleLowerLimit);
%      yl= [nanmin(dd(idx)) nanmax(dd(idx))];
%      %% add border not to make it too tight:
%      yl= yl + [-1 1]*opt.TightenBorder*diff(yl);
%      if strncmp(opt.ScalePolicy{ig},'tight',5),
%        yLim(ig,:)= yl;
%      else
%        %% determine nicer limits
%        dig= floor(log10(diff(yl)));
%        if diff(yl)>1,
%          dig= max(1, dig);
%        end
%        yLim(ig,:)= [trunc(yl(1),-dig+1,'floor') trunc(yl(2),-dig+1,'ceil')];
%      end
%    end
%    if isequal(opt.ScalePolicy{ig},'sym'),
%      yl= max(abs(yLim(ig,:)));
%      yLim(ig,:)= [-yl yl];
%    end
%    if any(isnan(yLim(ig,:))),
%      yLim(ig,:)= [-1 1];
%    end
%    if ig==1 & length(ax_idx)>1,
%  %    scale_with_group1= setdiff(1:nDisps, util_chanind(mnt.clab(DisplayChannels), ...
%  %                                                 [opt.ScaleGroup{2:end}]));
%  %    set(H{ih}.ax(scale_with_group1), 'yLim',yLim(ig,:));
%      ch2group= ones(1,nDisps);
%    else
%  %    set(H{ih}.ax(ax_idx), 'yLim',yLim(ig,:));
%      ch2group(ax_idx)= ig;
%      for ia= ax_idx,
%        if max(abs(yLim(ig,:)))>=100,
%          dig= 0;
%        elseif max(abs(yLim(ig,:)))>=1,
%          dig= 1;
%        else
%          dig= 2;
%        end
%        axestitle{ia}= sprintf('%s  [%g %g] %s', ...
%                               axestitle{ia}, ...
%                               trunc(yLim(ig,:), dig), opt.YUnit);
%      end
%    end
%  end
%warning(w_cm);

if length(s) == 3 
  s(4) = 1;
end

for ih = 1:s(4)
  figure(ih)
  clf;

  H{ih}.ax= zeros(1, nDisps);
  opt_plot= {'legend',1, 'title','', 'UnitDispPolicy','none', ...
            'GridOverPatches',0};
  if isfield(mnt, 'box') & isnan(mnt.box(1,end)),
    %% no grid position for legend available
    opt_plot{2}= 0;
  end

  cl = max(abs([min(min(min(squeeze(epo.x(:, :, :, ih))))) max(max(max(squeeze(epo.x(:, :, :, ih)))))]));
  cl = [-cl cl];
 
  maxposy = inf;
  maxposx = -inf;
  
  for ia= 1:nDisps,
    ic= DisplayChannels(ia);
    pos = get_axisGridPos(mnt, ic);
    if sum(isnan(pos)) == 0
      H{ih}.ax(ia)= axes('position', pos);

      if pos(2) < maxposy
        maxposy = pos(2);
        maxposx = pos(1)+pos(3);
      end
      if pos(2) == maxposy
        maxposx = max(maxposx, pos(1)+pos(3));
      end
      
      
    %    H{ih}.chan(ia)= plot_channel(epo, mnt.clab{ic}, opt_channel, opt_plot{:}, ...
    %                            'yLim', yLim(ch2group(ia),:), ...
    %                            'AxisTitle', axestitle{ia}, 'title',0, ...
    %                            'SmallSetup',1);
  %        H{ih}.chan = imagesc(epo.t, epo.f, squeeze(epo.x(:, :, ia, ih)));
        H{ih}.chan = contourf(epo.t, epo.f, squeeze(epo.x(:, :, ia, ih)));
        set(gca, 'CLim', cl, 'YTicklabel', [], 'XTicklabel', [])
        shading flat
        
        ylim = get(H{ih}.ax(ia), 'YLim');
        yloc = ylim(2) - (ylim(2)-ylim(1))*.075;
        xlim = get(H{ih}.ax(ia), 'XLim');
        xloc = xlim(2) - (xlim(2)-xlim(1))*.075;
        
        ytick = get(H{ih}.ax(ia), 'YTick');
        xtick = get(H{ih}.ax(ia), 'XTick');
      
        for ihorz = 1:length(xtick)
          hl = line(repmat(xtick, 2, 1), repmat(ylim', 1, length(xtick)), 'Color', 'k', 'LineStyle', ':');
        end
        for ivert = 1:length(ytick)
          hl = line(repmat(xlim', 1, length(ytick)), repmat(ytick, 2, 1), 'Color', 'k', 'LineStyle', ':');
        end
        line([0 0], ylim', 'Color', [0 0 0], 'LineStyle', '--');
        
        H{ih}.chan.text = text(xloc, yloc, axestitle(ia));
        set(H{ih}.chan.text, 'BackGroundColor', [1 1 1], 'Color', [0 0 0], 'VerticalAlignment', 'top', 'Horizontalalignment', 'right')
                
  %      if ic==DisplayChannels(1),
  %        opt_plot{2}= 0;
  %        H{ih}.leg= H{ih}.chan(ia).leg;
  %        leg_pos= get_axisGridPos(mnt, 0);
  %        if ~any(isnan(leg_pos)),
  %          leg_pos_orig= get(H{ih}.leg, 'position');
  %          if leg_pos(4)>leg_pos_orig(4),
  %            switch(lower(opt.LegendVerticalAlignment)), 
  %              case 'top',
  %               leg_pos(2)= leg_pos(2)-leg_pos_orig(4)+leg_pos(4);
  %             case 'middle',
  %               leg_pos(2)= leg_pos(2)+(leg_pos(4)-leg_pos_orig(4))/2;
  %            end
  %          end
  %          leg_pos(3:4)= leg_pos_orig(3:4);  %% use original size
  %          set(H{ih}.leg, 'position', leg_pos);
  %          ud= get(H{ih}.leg, 'userData');
  %          ud= set_defaults(ud, 'type','ERP plus', 'chan','legend');
  %          set(H{ih}.leg, 'Visible','off', 'userData',ud);
  %          set(get(H{ih}.leg,'children'), 'Visible','on');
  %        end
  %      end
    end
  end
      
  if isfield(mnt, 'scale_box') & all(~isnan(mnt.scale_box)),
    ax_idx= util_chanind(mnt.clab(DisplayChannels), opt.ScaleGroup{1});
    axes(H{ih}.ax(ax_idx(1)));
    H{ih}.scale= grid_addScale(mnt, opt);
  end

    pos = get_axisGridPos(mnt, ic+1);
    pos(3) = 0.075*pos(3);
    H{ih}.ax(ia+1) = axes('position', pos);
    set(gca, 'YTicklabel', '', 'XTicklabel', '')
    fa = find(H{ih}.ax);
    axes(H{ih}.ax(fa(1)))
    cb = Colorbar(H{ih}.ax(ia+1));
    set(get(cb, 'ylabel'), 'String', opt.CUnit)
%    plot_gridOverPatches('Axes',H{ih}.ax);
  
  if ~strcmp(opt.TitleDir, 'none'),
    tit= '';
    if isfield(opt, 'title'),
      tit= [opt.Title ':  '];
    elseif isfield(epo, 'title'),
      tit= [untex(epo.title) ':  '];
    end
    if isfield(epo, 'ClassName'),
      tit= [tit, epo.ClassName{ih} ', '];
    end
    if isfield(epo, 'N'),
      tit= [tit, 'N= ' str_vec2str(epo.N,[],'/') ',  '];
    end
    if isfield(epo, 't'),
      tit= [tit, sprintf('[%g %g] %s,  ', trunc(epo.t([1 end]), 0), opt.XUnit)];
    end
    if isfield(epo, 'f')
      tit= [tit, sprintf('[%g %g] %s  ', trunc(epo.f([1 end]), 0), opt.YUnit)];
    end
    if strcmpi(opt.YDir, 'reverse'),
      tit= [tit, ' neg. up'];
    end
    if isfield(opt, 'titleAppendix'),
      tit= [tit, ', ' opt.TitleAppendix];
    end
    H{ih}.title= addtitle(tit, opt.TitleDir);
  end
  
  if ~isempty(opt.ShiftAxesUp) & opt.ShiftAxesUp~=0,
    shift_axesUp(opt.ShiftAxesUp);
  end
  
  if nargout==0,
    clear H;
  end
end
