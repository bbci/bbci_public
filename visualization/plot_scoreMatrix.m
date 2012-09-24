function H= plot_scoreMatrix(epo_r, ival, varargin)

props= {'Mnt'              struct                                 'STRUCT'
        'VisuScalps'       1                                      'BOOL'
        'Colormap'         cmap_posneg(51),                       'CHAR|DOUBLE[- 3]'
        'MarkClab'         {'Fz','FCz','Cz','CPz','Pz','Oz'}      'CELL{CHAR}'
        'XUnit'            'ms'                                   'CHAR'
        'Title'            ''                                     'CHAR'
        'TitleSpec'        {}                                     'PROPLIST'
       };

if nargin==0,
  H= props; return
end

misc_checkType(epo_r, 'STRUCT(x t clab fs)');
misc_checkType(ival, 'DOUBLE[- 2]|STRUCT(ival)');

opt= opt_proplistToStruct(varargin{:});
[opt, isdefault]= opt_setDefaults(opt, props, 1);
[opt, isdefault]= ...
    opt_overrideIfDefault(opt, isdefault, ...
                          'Mnt', mnt_setElectrodePositions(epo_r.clab));

if isstruct(ival),
  ival= ival.ival;
end
% Sort intervals
[dmy, si]= sort(ival(:,1));
ival= ival(si,:);

% order channels for visualization:
%  scalp channels first, ordered from frontal to occipital (as returned
%  by function scalpChannels),
%  then non-scalp channels
clab= intersect(util_scalpChannels, strtok(epo_r.clab), 'stable');
clab_nonscalp= intersect(epo_r.clab, ...
                         setdiff(strtok(epo_r.clab), util_scalpChannels), ...
                         'stable');
epo_r= proc_selectChannels(epo_r, cat(2, clab, clab_nonscalp)); 

clf;
colormap(opt.Colormap);
if opt.VisuScalps,
  if isempty(opt.Title),
    subplotxl(2, 1, 1, [0.05 0 0.01], [0.06 0 0.1]);
  else
    subplotxl(2, 1, 1, [0.05 0 0.05], [0.06 0 0.1]);
  end
end
H.image= imagesc(epo_r.t, 1:length(epo_r.clab), epo_r.x'); 
H.ax= gca;
set(H.ax, 'CLim',[-1 1]*max(abs(epo_r.x(:)))); 
H.cb= colorbar;
if isfield(epo_r, 'yUnit'),
  ylabel(H.cb, sprintf('[%s]', epo_r.yUnit));
end
cidx= find(ismember(epo_r.clab,opt.MarkClab));
set(H.ax, 'YTick',cidx, 'YTickLabel',opt.MarkClab, ...
          'TickLength',[0.005 0]);
if isdefault.XUnit && isfield(epo_r, 'XUnit'),
  opt.XUnit= epo_r.XUnit;
end
xlabel(['[' opt.XUnit ']']);
ylabel('channels');
ylimits= get(H.ax, 'YLim');
set(H.ax, 'YLim',ylimits+[-2 2], 'NextPlot','add');
ylimits= ylimits+[-1 1];
for ii= 1:size(ival,1),
  xx= ival(ii,:) + [-1 0]*1000/epo_r.fs/2;
  H.box(:,ii)= line(xx([1 2; 2 2; 2 1; 1 1]), ...
                    ylimits([1 1; 1 2; 2 2; 2 1]), ...
                    'Color',[0 0.5 0], 'LineWidth',0.5);
end
if ~isempty(opt.Title),
  H.title= axis_title(opt.Title, 'VPos',0, 'VerticalAlignment','bottom', ...
                      'FontWeight','bold', 'FontSize',16, ...
                      'Color',0.3*[1 1 1], ...
                      opt.TitleSpec{:});
end

%set(H.ax_overlay, 'Visible','off');
if opt.VisuScalps,
  nIvals= size(ival,1);
  for ii= 1:nIvals,
    H.ax_scalp(ii)= subplotxl(2, nIvals, nIvals + ii);
  end
%  ival= visutil_correctIvalsForDisplay(ival, 'fs',epo_r.fs);
  H.h_scalp= plot_scalpEvolution(epo_r, opt.Mnt, ival, defopt_scalp_r, ...
                            'Subplot', H.ax_scalp, ...
                            'IvalColor', [0 0 0], ...
                            'GlobalCLim', 1, ...
                            'ScalePos','none');
  delete(H.h_scalp.text);
end
