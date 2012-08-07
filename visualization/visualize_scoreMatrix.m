function H= visualize_scoreMatrix(epo_r, ival, varargin)

props = {'mnt',             get_electrodePositions(epo_r.clab),     'STRUCT';
         'VisuScalps',      1,                                      'BOOL';
         'colormap',        cmap_posneg(51),                        'CHAR|DOUBLE[- 3]';
         'MarkClab',        {'Fz','FCz','Cz','CPz','Pz','Oz'},      'CELL{CHAR}';
         'XUnit',           'ms',                                   'CHAR'};

if nargin==0,
  H= props; return
end

opt= opt_proplistToStruct(varargin{:});
opt= opt_setDefaults(opt, props);
opt_checkProplist(opt, props);

epo_r= proc_selectChannels(epo_r, get_scalpChannels); %% order channels
clf;
colormap(opt.Colormap);
if opt.VisuScalps,
  subplotxl(2, 1, 1, [0.05 0 0.01], [0.05 0 0.05]);
end
H.image= imagesc(epo_r.t, 1:length(epo_r.clab), epo_r.x'); 
H.ax= gca;
set(H.ax, 'CLim',[-1 1]*max(abs(epo_r.x(:)))); 
H.cb= Colorbar;
cidx= strpatternmatch(opt.MarkClab, epo_r.clab);
set(H.ax, 'YTick',cidx, 'YTickLabel',opt.MarkClab, ...
          'TickLength',[0.005 0]);
if isdefault.xunit & isfield(epo_r, 'XUnit'),
  opt.XUnit= epo_r.XUnit;
end
xlabel(['[' opt.XUnit ']']);
ylabel('channels');
ylimits= get(H.ax, 'YLim');
set(H.ax, 'YLim',ylimits+[-2 2], 'NextPlot','add');
ylimits= ylimits+[-1 1];
for ii= 1:size(ival,1),
  xx= ival(ii,:);
  H.box(:,ii)= line(xx([1 2; 2 2; 2 1; 1 1]), ...
                    ylimits([1 1; 1 2; 2 2; 2 1]), ...
                    'Color',[0 0.5 0], 'LineWidth',0.5);
end

%set(H.ax_overlay, 'Visible','off');
if opt.VisuScalps,
  nIvals= size(ival,1);
  for ii= 1:nIvals,
    H.ax_scalp(ii)= subplotxl(2, nIvals, nIvals + ii);
  end
%  ival= visutil_correctIvalsForDisplay(ival, 'fs',epo_r.fs);
  H.h_scalp= plot_scalpEvolution(epo_r, opt.mnt, ival, defopt_scalp_r, ...
                            'Subplot', H.ax_scalp, ...
                            'IvalColor', [0 0 0], ...
                            'GlobalCLim', 1, ...
                            'ScalePos','none');
  delete(H.h_scalp.text);
end
