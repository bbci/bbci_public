function [ival, nfo, X_rem,H]= procutil_selectTimeIntervals(epo_r, varargin)
% PROCUTIL_SELECTTIMEINTERVALS - Select Intervals from Separability Score.
% Specially suited for ERP data. Caution: for oscillatory (ERD) data preferably
% select_timeival is used.
%
%Synopsis:
% [IVAL,NFO,X_REM,H] = procutil_selectTimeIntervals(EPO_R, <OPT>)
%
%Arguments:
%  ERP_R: structure of indices of discriminability, e.g., r-values,
%       Fisher-Scores, ROC-values
%  OPT: struct or property/value list of optional properties
%   'NIvals': number of intervals to be determined
%   'Sign':   constraint to look only for positive (sign=1) or
%       negative (sign=-1) values. Default sign=0 finds all.
%   'Clab': Criterion on consistent patterns operates on those channels,
%       default '*'.
%   'ClabPickPeak': The greedy algorithm to select intervals looks for
%       peak values in those channels
%   'IvalPickPeak': The greedy algorithm to select intervals looks for
%       peak values in this time interval
%   'IvalMax': All time intervals are chosen 'inside' this interval,
%       default [] meaning no limitation.
%   'Visualize': Value Matrix (EPO_R.x) and selected intervals are
%       visualized.
%   'VisuScalps': Scalp maps in selected intervals are visualize.
%   'Mnt': Struct of electrode montage for plotting scalp maps
%   'IntersampleTiming': [BOOLEAN] If true, the start and end points of
%       intervals are set to the time between two samples, i.e., instead
%       of [350 400] the function would return [345 405] (assuming fs=100).
%       This is in particular useful to avoid singleton intervals like
%       [100 100] which are forbidden in online processing with bbci_apply.
%   'Constraint': Constraints can be defined for the selection of intervals.
%       Each constraint is a cell array of 2 to 4 cells.
%         Cell 1: 'sign'
%         Cell 2: 'ivalPickPeak'
%         Cell 3: 'clabPickPeak', default '*'
%         Cell 4: 'ivalMax': interval does not exceed this limits
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
%      procutil_selectTimeIntervals(epo_r, 'Visualize', 1, 'VisuScalps', 1, ...
%                            'Clab',{'not','E*','Fp*','AF*'}, ...
%                            'Constraint', constraint);
%This should return 4 intervals, the first three with focus in the visual area
% (1: negative; 2: positive; 3: negative component) and the last with
% a positive focus in the centro-parietal area (P2).

% Author(s): Benjamin Blankertz
%            07-12 Johannes Hoehne, modified documentation and parameter
%            naming


props= { 'NIvals'               5               '!INT[1]';
    'Sign'                 0               '!INT[1]';
    'ScoreFactorForMax'    3               '!DOUBLE';
    'RRelThreshold'        0.5             '!DOUBLE';
    'CThreshold'           0.75            '!DOUBLE';
    'Clab'                 '*'             'CHAR|CELL{CHAR}';
    'ScalpChannelsOnly'    0               '!BOOL';
    'ClabPickPeak'         '*'             'CHAR|CELL{CHAR}';
    'IvalPickPeak'         []              'DOUBLE';
    'IvalMax'              []              'DOUBLE';
    'MinWidth'             []              'DOUBLE';
    'Sort'                 0               '!BOOL';
    'Visualize'            0               '!BOOL';
    'VisuScalps'           0               '!BOOL';
    'OptVisu'              []              'CELL|STRUCT';
    'Title'                ''              'CHAR'
    'Mnt'                  struct          'STRUCT';
    'Constraint'           {}              'CELL';
    'IntersampleTiming'    0               '!DOUBLE';
    'Verbose'              1               '!BOOL'};
props_plot= plot_scoreMatrix;

if nargin==0,
    ival= opt_catProps(props, props_plot);
    return;
end

misc_checkType(epo_r, 'STRUCT(x)');

opt= opt_proplistToStruct(varargin{:});
[opt, isdefault]= opt_setDefaults(opt, props);
opt_checkProplist(opt, props, props_plot);

[opt, isdefault]= opt_overrideIfDefault(opt, isdefault, ...
    'Mnt', ...
    mnt_setElectrodePositions(epo_r.clab));

if opt.ScalpChannelsOnly,
    scalpchans= intersect(strtok(epo_r.clab), util_scalpChannels);
    if length(scalpchans) < length(epo_r.clab),
        if isequal(opt.Clab, '*'),
            opt.Clab= intersect(epo_r.clab, util_scalpchans, 'stable');
        else
            selchans= epo_r.clab(util_chanind(epo_r, opt.Clab));
            opt.Clab= intersect(epo_r.clab, ...
                intersect(selchans, util_scalpChannels), 'stable');
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
    idx_keep= procutil_getIvalIndices(opt.IvalMax, epo_r);
    idx_rm= setdiff(1:size(epo_r.x,1), idx_keep,'legacy');
    epo_r.x(idx_rm,:)= 0;
end

if ~isempty(opt.Constraint)
    constraint= opt.Constraint;
    opt.Constraint= [];
    if opt.NIvals<length(constraint),
        opt.NIvals= length(constraint);
    end
    for ii= 1:opt.NIvals,
        if ii<=length(constraint),
            this_constraint= constraint{ii};
        else
            this_constraint= {opt.Sign, opt.IvalPickPeak, ...
                opt.ClabPickPeak, opt.IvalMax};
        end
        if length(this_constraint)<3,
            this_constraint{3}= '*';
        end
        if length(this_constraint)<4,
            this_constraint{4}=[];
        end
        
        %avoid visualization on every iteration
        tmp_opt=opt;
        tmp_opt.Visualize=0;
        
        [tmp_ival, tmp_nfo, X_rem]= ...
            procutil_selectTimeIntervals(epo_r, tmp_opt, ...
            'Sign', this_constraint{1}, ...
            'IvalPickPeak', this_constraint{2}, ...
            'ClabPickPeak', this_constraint{3}, ...
            'IvalMax', this_constraint{4}, ...
            'NIvals', 1);
        
        if isnan(tmp_ival(1)),
            continue;   %% there is nothing more to select
        else
            ival(ii,[1 2])= tmp_ival;
            nfo(ii)= tmp_nfo;
            idx_rm= procutil_getIvalIndices(tmp_ival, epo_r);
            epo_r.x(idx_rm,:)= 0;
        end
    end
    epo_r.x= X_memo;
    if opt.Sort,
        [dummy,si]= sort(ival(:,1));
        ival= ival(si,:);
    end
    if opt.Visualize,
        opt_plot= opt_substruct(opt, props_plot(:,1));
        H= plot_scoreMatrix(epo_r, nfo, opt_plot);
    else H= [];
    end
    return;
end

if opt.Verbose,
    nonscalp= setdiff(strtok(epo_r.clab), util_scalpChannels,'legacy');
    if ~isempty(nonscalp),
        util_warning(['Presumably non-scalp channel(s) found: ' ...
            str_vec2str(nonscalp)], ...
            'selectTimeIntervals:nonScalpChans', ...
            'Interval',10);
    end
end

if opt.NIvals>1,
    ii= 0;
    while ii<opt.NIvals,
        ii= ii+1;
        [tmp_ival, tmp_nfo, X_rem]= ...
            procutil_selectTimeIntervals(epo_r, opt, ...
            'Visualize', 0, ...
            'NIvals', 1);
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
        opt_plot= opt_substruct(opt, props_plot(:,1));
        H= plot_scoreMatrix(epo_r, cat(1, nfo.ival), opt_plot);
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
    pick_idx= procutil_getIvalIndices(opt.IvalPickPeak, epo_r);
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
    opt_plot= opt_substruct(opt, props_plot(:,1));
    H= plot_scoreMatrix(epo_r, cat(1, nfo.ival), opt_plot);
else
    H= [];
end

return





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
