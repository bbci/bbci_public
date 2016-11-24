function H= plot_scoreMatrix(epo_r, ival, varargin)
%PLOT_SCOREMATRIX - Visualizes score matrix of e.g. r-values
%
%Synposis:
% H= plot_scoreMatrix(EPO_R, IVAL, <OPTS>)
%
%Description:
% Visualizes the [Time x Channel] score matrix in epo_r and optionally
% plots scalp maps for given time intervals.
%
%Input:
% EPO_R: struct of score data as returned by e.g. proc_rSquareSigned
%        or proc_aucValues
% IVAL:  [nIvals x 2]-sized array of intervals, which are marked in
%        the score matrix and for which scalp topographies are drawn.
%        If ival is empty no scalp topographies are drawn.
% OPTS:  struct or property/value list of optional fields/properties:
%  .Mnt      - struct defining an electrode montage. Default is the
%              electrode montage returend by mnt_setElectrodePositions
%  .MarkClab - list of channels to be marked with labels on the y axis
%              of the score matrix. Default: Fz, FCz, Cz, CPz, Pz, Oz.
%
%Output:
% H: struct of handles to the created graphic objects.
%
%See also plot_scalpEvolution, plot_scalpPatternsPlusChannel

props= {'Mnt'         struct                               'STRUCT'
        'CLab'        '*'                                  'CHAR|CELL{CHAR}'
        'Colormap'    cmap_posneg(51),                     'CHAR|DOUBLE[- 3]'
        'MarkClab'    {'Fz','FCz','Cz','CPz','Pz','Oz'}    'CHAR|CELL{CHAR}'
        'XUnit'       'ms'                                 'CHAR'
        'Title'       ''                                   'CHAR'
        'TitleSpec'   {}                                   'PROPLIST'
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

if isempty(ival),
  opt.VisuScalps = 0;
else
  [opt, isdefault]= ...
      opt_overrideIfDefault(opt, isdefault, 'VisuScalps', 1);
end

epo_r= proc_selectChannels(epo_r, opt.CLab);
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
cidx= find(ismember(epo_r.clab,opt.MarkClab,'legacy'));
set(H.ax, 'YTick',cidx, 'YTickLabel',epo_r.clab(cidx), ...
          'TickLength',[0.005 0]);
if isdefault.XUnit && isfield(epo_r, 'xUnit'),
  opt.XUnit= epo_r.xUnit;
end
xlabel(['[' opt.XUnit ']']);
ylabel('channels');
ylimits= get(H.ax, 'YLim');
set(H.ax, 'YLim',ylimits+[-2 2], 'NextPlot','add');
ylimits= ylimits+[-1 1];

if opt.VisuScalps,
  if isstruct(ival)
    ival_struct= ival;
    ival= zeros(length(ival_struct),2);
    for ii= 1:length(ival_struct)
      ival(ii,:)= ival_struct(ii).ival;
    end
  end
  % Sort intervals
  [dummy,si]= sort(ival(:,1));
  ival= ival(si,:);
  
  for ii= 1:size(ival,1),
    xx= ival(ii,:);
    [dmy, ti]= min(abs(ival(ii,1) - epo_r.t));
    ti= max(2, ti);
    dist= diff(epo_r.t(ti+[-1 0]));
    xx(1)= xx(1) - 0.33*dist;
    [dmy, ti]= min(abs(ival(ii,2) - epo_r.t));
    ti= min(length(epo_r.t)-1, ti);
    dist= diff(epo_r.t(ti+[0 1]));
    xx(2)= xx(2) + 0.33*dist;
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
  
  nIvals= size(ival,1);
  for ii= 1:nIvals,
    H.ax_scalp(ii)= subplotxl(2, nIvals, nIvals + ii);
  end
  H.h_scalp= plot_scalpEvolution(epo_r, opt.Mnt, ival, defopt_scalp_r, ...
                                 'Subplot', H.ax_scalp, ...
                                 'IvalColor', [0 0 0], ...
                                 'GlobalCLim', 1, ...
                                 'ScalePos','none');
  delete(H.h_scalp.text);
end
