function [ival, nfo, X_rem,H]= select_time_intervals(epo_r, varargin)
% SELECT_TIME_INTERVALS - Select Discriminative Intervals from r-Matrix.
% Specially suited for ERP data. Caution: for oscillatory (ERD) data preferably
% select_timeival is used.
%
%Synopsis:
% [IVAL,NFO,X_REM,H] = select_time_intervals(EPO_R, <OPT>)
%
%Arguments:
%  ERP_R: structure of indices of discriminability, e.g., r-values,
%       Fisher-Scores, ROC-values
%  OPT: struct or property/value list of optional properties
%   'nIvals': number of intervals to be determined
%   'sign':   constraint to look only for positive (sign=1) or 
%       negative (sign=-1) values. Default sign=0 finds all.
%   'clab': Criterion on consistent patterns operates on those channels,
%       default '*'.
%   'clabPickPeak': The greedy algorithm to select intervals looks for
%       peak values in those channels
%   'ivalPickPeak': The greedy algorithm to select intervals looks for
%       peak values in this time interval
%   'ivalMax': All time intervals are chosen 'inside' this interval,
%       default [] meaning no limitation.
%   'visualize': Value Matrix (EPO_R.x) and selected intervals are
%   visualized.
%   'visuScalps': Scalp maps in selected intervals are visualize.
%   'intersampleTiming': [BOOLEAN] If true, the start and end points of
%       intervals are set to the time between two samples, i.e., instead
%       of [350 400] the function would return [345 405] (assuming fs=100).
%       This is in particular useful to avoid singleton intervals like
%       [100 100] which are forbidden in online processing with bbci_apply.
%   'constraint': Constraints can be defined for the selection of intervals.
%       Each constraint is a cell array of 2 to 4 cells.
%         Cell 1: 'sign'
%         Cell 2: 'ivalPickPeak'
%         Cell 3: 'clabPickPeak', default '*'
%         Cell 4: 'max_ival': interval does not exceed this limits
%       OPT.constraint is a cell array of such cells, see example below.
%       If OPT.nIvals is greater than the length of OPT.constraint,
%       the remaining intervals are determined without constraints.
%
%Returns:
%  IVAL: List of intervals
%  NFO:  Struct providing more information on the selection of intervals
%  H:    Handle to graphics objects (if visualize=1)
%
%
%Example:
%  constraint= ...
%      {{-1, [70 110], {'O#','PO7,8'}}, ...
%       {1, [90 130], {'O#','PO7,8'}}, ...
%       {-1, [120 180], {'O#','PO7,8'}}, ...
%       {1, [180 280], {'PO3-4','P3-4','CP3-4'}}};
%  [ival_scalps, nfo]= ...
%      select_time_intervals(epo_r, 'visualize', 1, 'visuScalps', 1, ...
%                            'clab',{'not','E*','Fp*','AF*'}, ...
%                            'constraint', constraint);
%This should return 4 intervals, the first three with focus in the visual area
% (1: negative; 2: positive; 3: negative component) and the last with
% a positive focus in the centro-parietal area (P2).

% Author(s): Benjamin Blankertz
%            07-12 Johannes Hoehne, modified documentation and parameter
%            naming


props= { 'NIvals'               5
         'Sign'                 0
         'ScoreFactorForMax'    3
         'RRelThreshold'        0.5
         'CThreshold'           0.75
         'Clab'                 '*'
         'ScalpChannelsOnly'    0
         'ClabPickPeak'         '*'
         'IvalPickPeak'         []
         'IvalMax'              []
         'MinWidth'             []
         'Sort'                 0
         'Visualize'            0
         'VisuScalps'           0
         'OptVisu'              []
         'Title'                ''
         'Mnt'                  get_electrodePositions(epo_r.clab)
         'Constraint'           {}
         'IntersampleTiming'    0
         'Verbose'              1 };

if nargin==0,
  ival = props; return
end

misc_checkType(epo_r, 'STRUCT(x)'); 


opt= opt_proplistToStruct(varargin{:});

[opt, isdefault]= opt_setDefaults(opt, props);
opt_checkProplist(opt, props);


if opt.ScalpChannelsOnly,
  scalpchans= intersect(strtok(epo_r.clab), scalpChannels);
  if length(scalpchans) < length(epo_r.clab),
    if isequal(opt.Clab, '*'),
      opt.Clab= clab_in_preserved_order(epo_r, scalpchans);
    else
      selchans= epo_r.clab(util_chanind(epo_r, opt.Clab));
      opt.Clab= clab_in_preserved_order(epo_r, ...
                                        intersect(selchans, scalpChannels));
    end
  end
  % in recursive calls we do not need to do this again
  opt.ScalpChannelsOnly= 0;
end

if ~isequal(opt.Clab, '*'),
  epo_r= proc_selectChannels(epo_r, opt.Clab);
  % in recursive calls we do not need to do this again
  opt.Clab= '*';
end

% save original score-matrix for visualization
X_memo= epo_r.x;

% delete scores where nothing should be selected
if ~isempty(opt.IvalMax),
  idx_keep= getIvalIndices(opt.IvalMax, epo_r);
  idx_rm= setdiff(1:size(epo_r.x,1), idx_keep);
  epo_r.x(idx_rm,:)= 0;
end

if ~isempty(opt.Constraint),
  constraint= opt.Constraint;
  opt.Constraint= [];
  if opt.NIvals<length(constraint),
    opt.NIvals= length(constraint);
  end
  for ii= 1:opt.NIvals,
    if ii<=length(constraint),
      this_constraint= constraint{ii};
    else
      this_constraint= {opt.Sign, opt.IvalPickPeak, opt.ClabPickPeak};
    end
    if length(this_constraint)<3,
      opt.Clab= '*';
    else
      opt.Clab= this_constraint{3};
    end
    tmp_r= epo_r;
    if length(this_constraint)>=4,
      % TODO: use new option ivalMax!
      idx_keep= getIvalIndices(this_constraint{4}, epo_r);
      idx_rm= setdiff(1:size(tmp_r.x,1), idx_keep);
      tmp_r.x(idx_rm,:)= 0;
    end
    [tmp_ival, tmp_nfo, X_rem]= ...
        select_time_intervals(tmp_r, opt, ...
                              'sign', this_constraint{1}, ...
                              'ivalPickPeak', this_constraint{2}, ...
                              'visualize', 0, ...
                              'nIvals', 1);
    if isnan(tmp_ival(1)),
      continue;   %% thiese is nothing more to select
    else
      ival(ii,[1 2])= tmp_ival;
      nfo(ii)= tmp_nfo;
      idx_rm= getIvalIndices(tmp_ival, epo_r);
      epo_r.x(idx_rm,:)= 0;
    end
  end
  epo_r.x= X_memo;
  if opt.Sort,
    [so,si]= sort(ival(:,1));
    ival= ival(si,:);
  end
  if opt.Visualize,
    H=visualize_score_matrix(epo_r, nfo, opt);
  else H=[];
  end
  return;
end

if opt.Verbose,
  nonscalp= setdiff(strtok(epo_r.clab), scalpChannels);
  if ~isempty(nonscalp),
    warning(['Presumably non-scalp channel(s) found: ' str_vec2str(nonscalp)]);
  end
end

if opt.NIvals>1,
  ii= 0;
  while ii<opt.NIvals,
    ii= ii+1;
    [tmp_ival, tmp_nfo, X_rem]= ...
        select_time_intervals(epo_r, opt, ...
                              'visualize', 0, ...
                              'nIvals', 1);
    if isnan(tmp_ival(1)),
      continue;   %% thiese is nothing more to select
    else
      ival(ii,[1 2])= tmp_ival;
      nfo(ii)= tmp_nfo;
      epo_r.x= X_rem;
    end
  end
  if opt.Sort,
    [so,si]= sort(ival(:,1));
    ival= ival(si,:);
  end
  if opt.Visualize,
    epo_r.x= X_memo;
    H= visualize_score_matrix(epo_r, nfo, opt);
  else 
    H= [];
  end
  return;
end

cidx= util_chanind(epo_r, opt.ClabPickPeak);
X0= epo_r.x(:,cidx);
T= size(X0,1);
score= zeros(1, T);
Xpos= max(X0, 0);
Xneg= min(X0, 0);
for tt= 1:T,
  sp= mean(Xpos(tt,:)) + max(Xpos(tt,:)) * opt.ScoreFactorForMax;
  sn= mean(Xneg(tt,:)) + min(Xneg(tt,:)) * opt.ScoreFactorForMax;
  if opt.Sign==0,
    score(tt)= sp - sn;
  elseif opt.Sign>0,
    score(tt)= sp;
  else
    score(tt)= -sn;
  end
end
clear Xpos Xneg

nfo.score= score;
if isempty(opt.IvalPickPeak),
  pick_idx= 1:length(score);
else
  pick_idx= getIvalIndices(opt.IvalPickPeak, epo_r);
end
[nfo.peak_val, t0]= max(nfo.score(pick_idx));
ti= pick_idx(t0);
[dmy, ci0]= max(abs(X0(ti,:)));
ci= cidx(ci0);

if nfo.peak_val==0,
  % This can only happen, if opt.Sign is specified, but no r-values of
  % that sign exist (or all r-values are 0).
  ival= [NaN NaN];
  X_rem= epo_r.x;
  return;
end

nfo.peak_clab= epo_r.clab{ci};
nfo.peak_time= epo_r.t(ti);

lti= enlarge_interval(epo_r.x, ti, -1, opt, nfo);
uti= enlarge_interval(epo_r.x, ti, 1, opt, nfo);
ival= epo_r.t([lti uti]);
if opt.IntersampleTiming,
  ival(:,1)= ival(:,1) - 1000/epo_r.fs/2;
  ival(:,2)= ival(:,2) + 1000/epo_r.fs/2;
end
nfo.ival= ival;

if nargout>2,
  X_rem= epo_r.x;
  X_rem([lti:uti],:)= 0;
end

if opt.Verbose>1,
  fprintf('r-square max (%.3g) spotted in %s at %.0f ms\n', ...
          nfo.peak_val, nfo.peak_clab, nfo.peak_time);
  fprintf('selected time interval [%.0f %.0f] ms\n', ival);
end

if opt.Visualize,
  epo_r.x= X_memo;
  H= visualize_score_matrix(epo_r, nfo, opt);
else
  H= [];
end

return




function H= visualize_score_matrix(epo_r, nfo, opt)

[optVisu, isdefault]= ...
    set_defaults(opt.OptVisu, ...
                 'clf', 1, ...
                 'colormap', cmap_posneg(51), ...
                 'markClab', {'Fz','FCz','Cz','CPz','Pz','Oz'}, ...
                 'xunit', 'ms', ...
                 'titleProp', {});

% order channels for visualization:
%  scalp channels first, ordered from frontal to occipital (as returned
%  by function scalpChannels),
%  then non-scalp channels
clab= clab_in_preserved_order(scalpChannels, strtok(epo_r.clab));
clab_nonscalp= clab_in_preserved_order(epo_r, ...
                       setdiff(strtok(epo_r.clab), scalpChannels));
epo_r= proc_selectChannels(epo_r, cat(2, clab, clab_nonscalp)); 
clf;
colormap(optVisu.colormap);
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
cidx= strpatternmatch(optVisu.markClab, epo_r.clab);
set(H.ax, 'YTick',cidx, 'YTickLabel',optVisu.markClab, ...
          'TickLength',[0.005 0]);
if isdefault.xunit && isfield(epo_r, 'xUnit'),
  optVisu.xunit= epo_r.xUnit;
end
xlabel(['[' optVisu.xunit ']']);
ylabel('channels');
ylimits= get(H.ax, 'YLim');
set(H.ax, 'YLim',ylimits+[-2 2], 'NextPlot','add');
ylimits= ylimits+[-1 1];
for ii= 1:numel(nfo),
  if ~isempty(nfo(ii).ival),
    xx= nfo(ii).ival + [-1 1]*1000/epo_r.fs/2;
    H.box(:,ii)= line(xx([1 2; 2 2; 2 1; 1 1]), ...
                      ylimits([1 1; 1 2; 2 2; 2 1]), ...
                      'color',[0 0.5 0], 'LineWidth',0.5);
  end
end
if ~isempty(opt.Title),
  H.title= axis_title(opt.Title, 'vpos',0, 'verticalAlignment','bottom', ...
                      'fontWeight','bold', 'fontSize',16, ...
                      'color',0.3*[1 1 1], ...
                      optVisu.titleProp{:});
end

%set(H.ax_overlay, 'Visible','off');
if opt.VisuScalps,
  nIvals= numel(nfo);
  for ii= 1:nIvals,
    H.ax_scalp(ii)= subplotxl(2, nIvals, nIvals + ii);
  end
  ival_scalps= visutil_correctIvalsForDisplay(cat(1,nfo.ival), 'fs',epo_r.fs);
  H.h_scalp= plot_scalpEvolution(epo_r, opt.Mnt, round(ival_scalps), defopt_scalp_r, ...
                            'Subplot', H.ax_scalp, ...
                            'IvalColor', [0 0 0], ...
                            'GlobalCLim', 1, ...
                            'ScalePos','none',...
                            'Extrapolate', 0);
  delete(H.h_scalp.text);
end

return;




function bti= enlarge_interval(X, ti, di, opt, nfo)

r_thr= nfo.peak_val * opt.RRelThreshold;
top_row= X(ti,:);
bti= ti;
goon= 1;
while goon && bti>1 && bti<size(X,1),
  bti= bti + di;
  if any(X(bti,:)),
    corr_with_toprow= nccorrcoef(top_row, X(bti,:));
    goon= nfo.score(bti) > r_thr & corr_with_toprow > opt.CThreshold;
  else
    goon= 0;
  end
end
if ~goon,
  bti= bti - di;
end



function r = nccorrcoef(x, y)
%NCCORRCOEF Compute non-centered correlation coefficient of X, Y

n= size(x, 2);
r= x*y' / sqrt(x*x') / sqrt(y*y');
