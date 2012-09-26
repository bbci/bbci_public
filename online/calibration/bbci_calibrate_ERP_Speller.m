function [bbci, data]= bbci_calibrate_ERP_Speller(bbci, data)
%BBCI_CALIBRATE_ERP_SPELLER - Calibrate online system for ERP Spellers
%
%This function is called by bbci_calibrate 
%(if BBCI.calibate.fcn is set to @bbci_calibrate_ERP_Speller).
%Via BBCI.calibrate.settings, the details can be specified, se below.
%
%Synopsis:
% [BBCI, DATA]= bbci_calibrate_ERP_Speller(BBCI, DATA)
% 
%Arguments:
%  BBCI -  the field 'calibrate' holds parameters specific to ERP Spellers.
%  DATA -  holds the calibration data
%  
%Output:
%  BBCI - Updated BBCI structure in which all necessary fields for
%     online operation are set, see bbci_apply_structures.
%  DATA - As input but added some information of the analysis that might
%     be reused in a second run
%
%BBCI.calibrate.settings may include the following parameters:
%  ...to.be.filled.in...
%  'cue_markers': Markers that trigger the classification of an ERP,
%          default: [11:16,21:26,31:36,41:46]

% 11-2011 Benjamin Blankertz


default_grd= sprintf(['scale,FC3,FC1,FCz,FC2,FC4,legend\n' ...
                     'C5,C3,C1,Cz,C2,C4,C6\n' ...
                     'CP5,CP3,CP1,CPz,CP2,CP4,CP6\n' ...
                     'P7,P5,P3,Pz,P4,P6,P8\n' ...
                     'PO7,PO3,O1,Oz,O2,PO4,PO8']);

props= {'ref_ival'      [-200 0]                       '!DOUBLE[1 2]'
        'disp_ival'     [-200 800]                     '!DOUBLE[1 2]'
        'clab'          '*'                            'CHAR|CELL[CHAR}'
        'cfy_clab'      {'not','E*','Fp*','A*'}        'CHAR|CELL{CHAR}'
        'cfy_ival'                    'auto'           'CHAR(auto)|DOUBLE[- 2]'
        'cfy_ival_pick_peak'          [100 700]        'DOUBLE[1 2]'
        'band'                        []               'DOUBLE[1 2]|DOUBLE[1]'
        'control_per_stimulus'        0                'BOOL'
        'model'             @train_RLDAshrink          'FUNC|CELL'
        'nSequences'                  5                'INT'
        'nClasses'                    0                'INT'
        'cue_markers'       [11:16,21:26,31:36,41:46]  '!DOUBLE[1 -]'
        'cfy_maxival'                 []               'DOUBLE[1 2]'
        'reject_artifacts'            1                'BOOL'
        'reject_artifacts_opts'       {}               'PROPLIST'
        'reject_channels'             1                'BOOL'
        'reject_eyemovements'         0                'BOOL'
        'reject_eyemovements_crit'    []               'STRUCT'
        'grd'                         default_grd      'CHAR'
        'clab_erp'                    {'Cz','PO7'}     'CHAR|CELL{CHAR}'
        'clab_rsq'                    {}               'CHAR|CELL{CHAR}'
        'target_dist'                 0                'INT'
        'mrk2feedback_fcn'   @(x)(1+mod(x-1,10))       'FUNC'
        'create_figs'                 1                'BOOL'
       };
[opt, isdefault]= opt_setDefaults('bbci.calibrate.settings', props);

nClassesGuess= length(unique(opt.mrk2feedback_fcn(opt.cue_markers)));
[opt, isdefault]= ...
  opt_overrideIfDefault(opt, isdefault, 'nClasses', nClassesGuess);
[opt, isdefault]= ...
  opt_overrideIfDefault(opt, isdefault, 'clab_rsq', opt.clab_erp);

default_crit_ival= [100 800];
default_crit_ival(1)= max(opt.disp_ival(1), default_crit_ival(1));
default_crit_ival(2)= min(opt.disp_ival(2), default_crit_ival(2));
default_crit= {'maxmin'  100                        'DOUBLE[1]'
               'clab'    {{'EOG*','F9,10','Fp*'}}   'CHAR|CELL{CHAR}'
               'ival'    default_crit_ival          'DOUBLE[1 2]'
              };
[opt, isdefault]= ...
  opt_overrideIfDefault(opt, isdefault, 'reject_eyemovements_crit', ...
                        opt_propspecToStruct(default_crit));

% add possibly missing fields to opt.reject_eyemovements_crit
opt.reject_eyemovements_crit= ...
  opt_setDefaults(opt.reject_eyemovements_crit, default_crit);

[opt, isdefault]= ...
  opt_overrideIfDefault(opt, isdefault, ...
                        'clab_rsq', opt.clab_erp);

% store chosen default settings back in bbci variable
bbci.calibrate.settings= opt;

opt_scalp_erp= defopt_scalp_erp('colorOrder', [0.9 0 0.9; 0.4 0.4 0.4]);
opt_scalp_r= defopt_scalp_r;

mnt= mnt_setGrid(data.mnt, opt.grd);

if ~data.isnew && isfield(data, 'result'),
  previous= data.result;
else
  previous= struct;
end

if ~isempty(opt.band),
  [filt_b,filt_a]= cheby2(5, 20, opt.band/data.cnt.fs*2);
  data.cnt = proc_filt(data.cnt, filt_b, filt_a);
end


BC_result= [];
BC_result.mrk= data.mrk;

BC_result.clab= data.cnt.clab(util_chanind(data.cnt, opt.clab));
BC_result.cfy_clab= data.cnt.clab(util_chanind(data.cnt, opt.cfy_clab));
% The following figures are always generated
if opt.create_figs,
    data.figure_handles= [1 2 4 6];
end

if opt.target_dist,
  [BC_result.mrk, BC_result.selected_trials]= ...
      mrk_selectTargetDist(BC_result.mrk, opt.target_dist);
else
  BC_result.selected_trials= NaN;
end


%% --- Artifact rejection (trials and/or channels) based on variance criterion
%
flds= {'reject_artifacts', 'reject_channels', ...
       'reject_artifacts_opts', 'target_dist', 'clab'};
if data.isnew || ~isfield(data, 'previous_settings') || ...
      ~struct_areFieldsEqual(opt, data.previous_settings, flds),
  BC_result.rejected_trials= NaN;
  BC_result.rejected_clab= NaN;
  if opt.reject_artifacts | opt.reject_channels,
    if opt.create_figs, 
        fig_set(5, 'name','Artifact rejection');         
        data.figure_handles(end+1)= 5;
    end
    [mk_clean , rClab, rTrials]= ...
        reject_varEventsAndChannels(data.cnt, BC_result.mrk, ...
                                    opt.disp_ival, ...
                                    'CLab',BC_result.clab, ...
                                    'DoMultipass', 1, ...
                                    'Verbose', 1, ...
                                    'Visualize', opt.create_figs, ...
                                    opt.reject_artifacts_opts{:});
    if opt.reject_artifacts,
      bbci_log_write(data, 'Rejected: %d trial(s).', length(rTrials));
      BC_result.mrk= mrk_selectEvents(BC_result.mrk, 'not',rTrials);
      BC_result.rejected_trials= rTrials;
    end
    if opt.reject_channels,
      bbci_log_write(data, 'Rejected channels: <%s>', str_vec2str(rClab));
      BC_result.rejected_clab= rClab;
    end
  else
    % Avoid confusion with old figure from previous run
    fig_closeIfExists(5);
  end
  if iscell(BC_result.rejected_clab),   %% that means rejected_clab is not NaN
    cidx= find(ismember(BC_result.clab, BC_result.rejected_clab));
    BC_result.clab(cidx)= [];
    cidx= find(ismember(BC_result.cfy_clab, BC_result.rejected_clab));
    BC_result.cfy_clab(cidx)= [];
  end
else
  result_flds= {'rejected_trials', 'rejected_clab', 'clab', 'cfy_clab'};
  BC_result= struct_copyFields(BC_result, previous, result_flds);
end


%% --- Segmentation and baselining ---
%
epo= proc_segmentation(data.cnt, BC_result.mrk, opt.disp_ival, ...
                       'clab', BC_result.clab);

%% Rejection of eyemovements based on max-min criterium 
%
if opt.reject_eyemovements && opt.reject_eyemovements_crit.maxmin>0,
  [epo, iArte]= ...
      proc_rejectArtifactsMaxMin(epo, ...
                                 opt.reject_eyemovements_crit.maxmin, ...
                                 'clab', opt.reject_eyemovements_crit.clab, ...
                                 'ival', opt.reject_eyemovements_crit.ival, ...
                                 'verbose',1);
  BC_result.mrk= mrk_selectEvents(BC_result.mrk, 'not',iArte);
  BC_result.eyemovement_trials= iArte;
else
  BC_result.eyemovement_trials= NaN;
end

epo= proc_baseline(epo, opt.ref_ival, 'channelwise', 1);


%% --- Plot r^2 matrix and select intervals if requested ---
%
%epo_r= proc_rSquareSigned(proc_selectChannels(epo,BC_result.cfy_clab));
epo_r= proc_rSquareSigned(epo);
epo_r.className= {'sgn r^2 ( T , NT )'};  %% just make it shorter
if opt.create_figs, 
  fig_set(6, 'name','r^2 Matrix', 'set',{'Visible','off'});
end
if isempty(opt.cfy_ival) || isequal(opt.cfy_ival, 'auto'),
  [BC_result.cfy_ival, nfo]= ...
      select_time_intervals(epo_r, 'Visualize', opt.create_figs, ...
                            'VisuScalps', opt.create_figs, ...
                            'Sort', 1, ...
                            'IntersampleTiming', 1, ...
                            'IvalPickPeak', opt.cfy_ival_pick_peak, ...
                            'IvalMax', opt.cfy_maxival);
  bbci_log_write(data.log.fid, 'Selected time intervals:');
  bbci_log_write(data.log.fid, '  [%g %g] ms', BC_result.cfy_ival');
else
  BC_result.cfy_ival= opt.cfy_ival;
  if opt.create_figs, 
    plot_scoreMatrix(epo_r, BC_result.cfy_ival); 
  end
end
if opt.create_figs, 
  set(gcf,  'Visible','on');
end


%% --- Visualize ERPs ---
%
if opt.create_figs,
  fig_set(1, 'name','ERP - grid plot', 'set',{'Visible','off'});
  H= grid_plot(epo, mnt, defopt_erps, 'ColorOrder',opt_scalp_erp.colorOrder);
  %grid_markInterval(BC_result.cfy_ival);
  if isfield(H, 'scale'),
    grid_addBars(epo_r, 'HScale',H.scale);
  else
    grid_addBars(epo_r);
  end
  set(gcf,  'Visible','on');
  
  fig_set(2, 'name','ERP - scalp maps', 'set',{'Visible','off'});
  H= plot_scalpEvolutionPlusChannel(epo, mnt, opt.clab_erp, BC_result.cfy_ival, ...
                               opt_scalp_erp);
  grid_addBars(epo_r);
  set(gcf,  'Visible','on');
  
  if isempty(opt.clab_rsq) || isequal(opt.clab_rsq,'auto'),
    opt.clab_rsq= unique_unsort({nfo.peak_clab}, 4);
  end
  fig_set(4, 'name','ERP - r^2 scalp maps', 'set',{'Visible','off'});
  plot_scalpEvolutionPlusChannel(epo_r, mnt, opt.clab_rsq, ...
                                 BC_result.cfy_ival, ...
                                 opt_scalp_r);
  set(gcf,  'Visible','on');
  clear epo*
end


%% --- Feature extraction ---
%
BC_result.ref_ival= opt.ref_ival;
BC_result.nSequences= opt.nSequences; %% Future extension: select by simulation

bbci.signal.clab= BC_result.cfy_clab;

if ~isempty(opt.band)  %set filter if required!
  online_fs= data.cnt.fs;   %extract sampling rate from bbci-strukt 
  [filt_b,filt_a]= cheby2(5, 20, opt.band/online_fs*2);
  bbci.signal.proc= {{@online_filt, filt_b, filt_a}};
end

if isempty(opt.ref_ival),     % no baselining
  bbci.feature.proc= {{@proc_jumpingMeans, BC_result.cfy_ival}}; 
  min_t = min(BC_result.cfy_ival(:));
else
  bbci.feature.proc= {{@proc_baseline, BC_result.ref_ival, 'beginning_exact'}, ...
                      {@proc_jumpingMeans, BC_result.cfy_ival}};
  min_t =  min(BC_result.ref_ival(1), min(BC_result.cfy_ival(:)));
end
bbci.feature.ival= [min_t BC_result.cfy_ival(end)];

if opt.control_per_stimulus,
  bbci.control.fcn= @bbci_control_ERP_Speller_binary;
else
  bbci.control.fcn= @bbci_control_ERP_Speller;
end
bbci.control.param= {struct('nClasses',         opt.nClasses, ...
                            'nSequences',       BC_result.nSequences, ...
                            'mrk2feedback_fcn', opt.mrk2feedback_fcn)};
bbci.control.condition.marker= opt.cue_markers;
if ~isfield(bbci, 'quit_condition') || ~isfield(bbci.quit_condition, 'marker'),
  bbci.quit_condition.marker = 255;
end

fv= proc_segmentation(data.cnt, BC_result.mrk, bbci.feature.ival, ...
                       'clab',bbci.signal.clab);
fv= bbci_calibrate_evalFeature(fv, bbci.feature);

bbci.classifier.C= trainClassifier(fv, opt.model);

opt_xv= struct('xTrials',       [1 10], ...
               'loss_fcn',      @loss_rocArea, ...
               'verbosity',     0);

[loss, dum, outTe]= xvalidation(fv, opt.model, opt_xv);
me= val_confusionMatrix(fv, outTe, 'mode','normalized');
bbci_log_write(data.log.fid, ['ROC-loss: %.1f%%  |  ' ...
                    'Correct Hits: %.1f%%,  Correct Miss: %.1f%%'], ...
               100*loss, 100*me(1,1), 100*me(2,2));

data.feature= fv;
data.result= BC_result;
data.result.rocloss = 100*loss;
data.result.me = me;
