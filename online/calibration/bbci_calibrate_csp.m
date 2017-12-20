function [bbci, data]= bbci_calibrate_csp(bbci, data)
%BBCI_CALIBRATE_CSP - Calibrate CSP-based detection of SMR Modulations
%
%This function is called by bbci_calibrate 
%(if BBCI.calibate.fcn is set to @bbci_calibrate_csp).
%Via BBCI.calibrate.settings, the details can be specified, see below.
%
%Synopsis:
% [BBCI, DATA]= bbci_calibrate_CSP(BBCI, DATA)
% 
%Arguments:
%  BBCI -  the field 'calibrate.settings' holds parameters specific to
%          calibrate CSP-based BCI processing.
%  DATA -  holds the calibration data
%  
%Output:
%  BBCI - Updated BBCI structure in which all necessary fields for
%     online operation are set, see bbci_apply_structures.
%  DATA - As input but added some information of the analysis that might
%     be reused in a second run
%
%BBCI.calibrate.settings may include the following parameters:
%  classes: [1x2 CELL of CHAR] Names of the two classes, which are to be
%     discriminated. For classes = 'auto', all pairs of available classes
%     are investigated, and the one with best xvalidation performance is
%     chosen. Default is 'auto'.
%  ival: [1x2 DOUBLE] interval on which CSP is performed, 'auto' means
%     automatic selection. Default is 'auto'.
%  band: [1x2 DOUBLE] frequency band on which CSP is performed, 'auto' means
%     automatic selection. Default is 'auto'.
%  clab: [CELL] Labels of the channels that are used for classification,
%     default {'not','E*','Fp*','AF*','OI*','I*','*9','*10'}.
%  nPatters: [INT>0] number of CSP patterns which are considered from each
%     side of the eigenvalue spectrum. Note, that not neccessarily all of
%     these are used for classification, see settings.pattern.
%     Default is 3.
%  patterns: [1xN DOUBLE or 'auto'] vector specifying the indices of the
%     CSP filters that should be used for classification; 'auto' means
%     automatic selection. Default is 'auto'.
%     Currently only option 'auto' is implemented!
%  model: [CHAR or CELL] Classification model.
%     Default {@train_RLDAshrink, 'gamma',0, store_means',1, 'scaling',1}.
%  reject_artifacts:
%  reject_channels:
%  reject_artifacts_opts: cell array of options which are passed to 
%     reject_varEventsAndChannels.
%  check_ival: interval which is checked for artifacts
%  do_laplace: do Laplace spatial filtering for automatic selection
%     of ival/band. If opt.do_laplace is set to 0, the default value of
%     will also be set to opt.visu_laplace 0 (but can be overwritten).
%  visu_laplace: do Laplace filtering for grid plots of Spectra/ERDs.
%     If visu_laplace is a string, it is passed to proc_laplace. This
%     can be used to use alternative geometries, like 'vertical'.
%  visu_band: Frequency range for which spectrum is shown.
%  visu_ival: Time interval for which ERD/ERS curves are shown.
%  grd: grid to be used in the grid plots of spectra and ERDs.
%
%Only the figures of the chosen class combination are visible, while the
%others are hidden. In order to make them visible, type
%>> set(cat(2, data.all_results.figure_handles), 'Visible','on')
%
%You might like to modify bbci.feature.ival after running this function.
%
%Discussion of CSP related validation issues, see
%  [Lemm et al, NeuroImage 2011].

% 11-2011 Benjamin Blankertz
% 06-2012 Javier Pascual. Added  'laplace_require_neighborhood', 1


default_clab=  {'not','E*','Fp*','AF*','OI*','I*','*9','*10'};
default_grd= ...
    sprintf(['scale,_,F3,Fz,F4,_,legend\n' ...
             'FC5,FC3,FC1,FCz,FC2,FC4,FC6\n' ...
             'C5,C3,C1,Cz,C2,C4,C6\n' ...
             'CP5,CP3,CP1,CPz,CP2,CP4,CP6\n' ...
             'P5,P3,P1,Pz,P2,P4,P6']);
default_colDef= {'left',      'right',   'foot',  'rest'; ...
                 [0.8 0 0.8], [0 0.7 0], [0 0 1], [0 0 0]};
default_model= {@train_RLDAshrink, 'Gamma',0, 'StoreMeans',1, 'Scaling',1};

props= {'classes'    'auto'  
        'visu_ival'    [-500 5000]
        'visu_band'    [5 35]
        'visu_laplace'    1
        'clab'    default_clab
        'laplace_require_neighborhood'    1
        'ival'    'auto'  
        'band'    'auto'  
        'nPatterns'    3
        'patterns'    'auto'  
        'model'    default_model
        'reject_artifacts'    1
        'reject_channels'    1 
        'reject_artifacts_opts'    {'clab', default_clab}
        'reject_outliers'    0
        'check_ival'    [500 4500]
        'default_ival'    [1000 3500]
        'min_ival_length'    300
        'enlarge_ival_append'    'end'  
        'selband_opt'    []
        'selival_opt'    []
        'filtOrder'    5
        'do_laplace'    1
        'grd'    default_grd
        'colDef'    default_colDef
       };

[opt, isdefault]= opt_setDefaults('bbci.calibrate.settings', props);
if isdefault.visu_laplace && ~opt.do_laplace,
  opt.visu_laplace= 0;
end

% store chosen default settings back in bbci variable
bbci.calibrate.settings= opt;


%% -- Prepare visualization --
%
mnt= mnt_setGrid(data.mnt, opt.grd);
opt_grid= defopt_erps;
%% TODO: extract good channel (like 'Pz' here) from grid
opt_grid_spec= defopt_spec('XTickAxes','Pz');

if sum(ismember(opt.colDef(1,:), data.mrk.className)) < ...
      length(data.mrk.className),
  if ~isdefault.colDef,
    warning('opt.colDef does not match with data.mrk.className');
  end
  nClasses= length(data.mrk.className);
  cols= mat2cell(cmap_rainbow(nClasses), ones(1,nClasses), 3)';
  opt.colDef= {data.mrk.className{:}; cols{:}};
end


if ~data.isnew && isfield(data, 'result'),
  previous= data.result;
  data= rmfield(data, 'result');
else
  previous= struct;
end

BC_result= [];
BC_result.mrk= data.mrk;
BC_result.clab= data.cnt.clab(util_chanind(data.cnt, opt.clab));

mrk_all= data.mrk;


%% --- Artifact rejection (trials and/or channels) based on variance criterion
%
flds= {'reject_artifacts', 'reject_channels', ...
       'reject_artifacts_opts', 'clab'};
if data.isnew || ~isfield(data, 'previous_settings') || ...
      ~struct_areFieldsEqual(opt, data.previous_settings, flds),
  BC_result.rejected_trials= NaN;
  BC_result.rejected_clab= NaN;
  if opt.reject_artifacts || opt.reject_channels,
    fig_state= fig_set(5, 'Hide',1, 'Name','Artifact rejection');
    [mk_clean , rClab, rTrials]= ...
        reject_varEventsAndChannels(data.cnt, mrk_all, opt.check_ival, ...
                                    'DoMultipass', 1, ...
                                    'Visualize', 1, ...
                                    opt.reject_artifacts_opts{:});
    if opt.reject_artifacts,
      bbci_log_write(data, 'Rejected: %d trial(s).', length(rTrials));
      BC_result.rejected_trials= rTrials;
    end
    if opt.reject_channels,
      bbci_log_write(data, 'Rejected channels: <%s>', str_vec2str(rClab));
      BC_result.rejected_clab= rClab;
    end
    fig_publish(fig_state);
  else
    % Avoid confusion with old figure from previous run
    fig_closeIfExists(3);
  end
  if iscell(BC_result.rejected_clab),   %% that means rejected_clab is not NaN
    cidx= find(ismember(BC_result.clab, BC_result.rejected_clab));
    BC_result.clab(cidx)= [];
  end
else
  result_flds= {'rejected_trials', 'rejected_clab', 'clab'};
  BC_result= struct_copyFields(BC_result, previous, result_flds);
end

if isequal(opt.classes, 'auto'),
  class_combination= nchoosek(1:size(mrk_all.y,1), 2);
else
  class_combination= find(ismember(mrk_all.className, opt.classes));
  if length(class_combination) < length(opt.classes),
    error('Not all specified classes were found.');
  end
  if length(class_combination) ~= 2,
    error('This calibration is only for binary classification.');
  end
end

memo_opt.band= opt.band;
memo_opt.ival= opt.ival;
clear mean_loss std_loss


%% -- Specific investigation of binary class combination(s) starts here --
%
for ci= 1:size(class_combination,1),
 
figno_offset= 4*(ci-1);
classes= mrk_all.className(class_combination(ci,:));
if strcmp(classes{1},'right') || strcmp(classes{2},'left'),
  class_combination(ci,:)= fliplr(class_combination(ci,:));
  classes= mrk_all.className(class_combination(ci,:));
end
msg= sprintf('\n** Class combination <%s> vs <%s> **\n', classes{:});
bbci_log_write(data, msg);
mrk2= mrk_selectClasses(mrk_all, classes);
BC_result.mrk= mrk2;
BC_result.classes= classes;

[~, cidx]= intersect(opt.colDef(1,:), mrk_all.className, 'stable');
opt_grid.colorOrder= cat(1, opt.colDef{2,cidx});
opt_grid.lineStyleOrder= {'--','--','--'};
clidx= find(ismember(mrk_all.className, classes));
opt_grid.lineStyleOrder(clidx)= {'-'};
opt_grid_spec.lineStyleOrder= opt_grid.lineStyleOrder;
opt_grid_spec.colorOrder= opt_grid.colorOrder;


%% --- Automatic selection of parameters (band, ival) ---
%
opt.band= memo_opt.band;    %% for classes='auto' do sel. for each combination
opt.ival= memo_opt.ival;
band_fresh_selected= 0;
if isequal(opt.band, 'auto') || isempty(opt.band);
  bbci_log_write(data, 'No band specified, automatic selection:');
  if ~isequal(opt.ival, 'auto') & ~isempty(opt.ival),
    ival_for_bandsel= opt.ival;
  else
    ival_for_bandsel= opt.default_ival;
  end
  opt.band= select_bandnarrow(data.cnt, mrk2, ival_for_bandsel, ...
                              opt.selband_opt{:}, 'DoLaplace',opt.do_laplace);
  bbci_log_write(data, ' -> [%g %g] Hz', opt.band);
  band_fresh_selected= 1;
end

[filt_b,filt_a]= butter(opt.filtOrder, opt.band/data.cnt.fs*2);
clear cnt_flt
cnt_flt= proc_filt(data.cnt, filt_b, filt_a);

if isequal(opt.ival, 'auto') || isempty(opt.ival),
  bbci_log_write(data, 'No ival specified, automatic selection:');
  opt.ival= select_timeival(cnt_flt, mrk2, ...
                            opt.selival_opt, 'DoLaplace',opt.do_laplace);
  bbci_log_write(data, ' -> [%i %i] msec', opt.ival);
end

if band_fresh_selected && ~isequal(opt.ival, ival_for_bandsel),
  bbci_log_write(data, 'Redoing selection of freq. band for new interval:');
  first_selection= opt.band;
  opt.band= select_bandnarrow(data.cnt, mrk2, opt.ival, ...
                              opt.selband_opt{:}, 'DoLaplace',opt.do_laplace);
  bbci_log_write(data, ' -> [%g %g] Hz', opt.band);
  if ~isequal(opt.band, first_selection),
    clear cnt_flt
    [filt_b,filt_a]= butter(opt.filtOrder, opt.band/data.cnt.fs*2);
    cnt_flt= proc_filt(data.cnt, filt_b, filt_a);
  end
end


%% -- Visualization of Spectra and ERD/ERS curves --
%
disp_clab= gridutil_getClabOfGrid(mnt);
if opt.visu_laplace,
  requ_clab= procutil_getClabForLaplacian(data.cnt, disp_clab);
else
  requ_clab= disp_clab;
end

%% -- Spectra --
name= sprintf('Spectra in [%d %d] ms', opt.ival);
fig_state= fig_set(figno_offset+1, 'Hide',1, 'Name',name);
if diff(opt.ival)>=opt.min_ival_length,
  tmp_ival= opt.ival;
else
  bbci_log_write(data, '!Enlarging interval to calculate spectra.');
  switch(opt.enlarge_ival_append),
   case 'start',
    tmp_ival= opt.ival(2) + [-opt.min_ival_length 0];
   case 'end',
    tmp_ival= opt.ival(1) + [0 opt.min_ival_length];
   otherwise
    error('opt.enlarge_ival_append option unknown.')
  end
end
spec= proc_segmentation(data.cnt, mrk_all, tmp_ival, 'CLab',requ_clab);

if opt.visu_laplace,
  spec= proc_laplacian(spec, 'requireCompleteNeighborhood', ...
                       opt.laplace_require_neighborhood);
end
if data.cnt.fs>size(spec.x,1)
  winlen= size(spec.x,1);
else
  winlen= data.cnt.fs;
end
spec= proc_spectrum(spec, opt.visu_band, kaiser(winlen, 2));
spec_rsq= proc_rSquareSigned(proc_selectClasses(spec, classes));

h= grid_plot(spec, mnt, opt_grid_spec);
grid_markInterval(opt.band);
grid_addBars(spec_rsq, 'HScale', h.scale);
fig_publish(fig_state);  
clear erd erd_rsq;


%% -- ERD/ERS --
name= sprintf('ERD-ERS for [%g %g] Hz', opt.band);
fig_state= fig_set(figno_offset+2, 'Hide',1, 'Name',name);
erd= proc_selectChannels(cnt_flt, requ_clab);
if opt.visu_laplace,
  erd= proc_laplacian(erd,'RequireCompleteNeighborhood', opt.laplace_require_neighborhood);
end
erd= proc_envelope(erd, 'MovAvgMsec', 200);
erd= proc_segmentation(erd, mrk_all, opt.visu_ival);
erd= proc_baseline(erd, [], 'trialwise',0);
erd_rsq= proc_rSquareSigned(proc_selectClasses(erd, classes));

h= grid_plot(erd, mnt, opt_grid);
grid_markInterval(opt.ival);
grid_addBars(erd_rsq, 'HScale', h.scale);
fig_publish(fig_state);
clear erd erd_rsq;


%% --- Feature extraction ---
%
BC_result.ival= opt.ival;
BC_result.band= opt.band;
BC_result.csp_b= filt_b;
BC_result.csp_a= filt_a;

bbci.signal.clab= BC_result.clab;

fv= proc_segmentation(cnt_flt, mrk2, BC_result.ival, 'CLab',bbci.signal.clab);
clear cnt_flt

if isequal(opt.patterns,'auto'),
  % we should get rid of the proc_cspAuto function. Implement the heuristic
  % as a procutil_selectSmartCsps and use that here:
  [fv2, csp_w, A, la]= proc_csp(fv, 'SelectFcn',...
                                {@cspselect_directorsCut, opt.nPatterns});
else
  [fv2, csp_w, A, la]= proc_csp(fv, 'SelectFcn',...
                                {@cspselect_equalPerClass, opt.nPatterns});
end
fig_state= fig_set(figno_offset+4, 'Hide',1, ...
                   'Name', sprintf('CSP %s vs %s', classes{:}));
if isequal(opt.patterns,'auto'),
  plot_cspAnalysis(fv, mnt, csp_w, A, la, ...
                  'RowLayout',1, 'Title','');
else
  plot_cspAnalysis(fv, mnt, csp_w, A, la, opt_scalp_csp, ...
                   'MarkPatterns', opt.patterns);
end
fig_publish(fig_state);

bbci.feature.ival= [-750 0];
bbci.feature.proc= {@proc_variance, @proc_logarithm};

fv2= bbci_calibrate_evalFeature(fv2, bbci.feature);
%if ~isequal(opt.patterns,'auto'),
%  fv2.x= fv2.x(opt.patterns,:);
%  csp_w= csp_w(:,opt.patterns);
%end

BC_result.feature= fv2;
BC_result.csp_w= csp_w;
bbci.signal.proc= {{@online_linearDerivation, BC_result.csp_w}, ...
                   {@online_filt, BC_result.csp_b, BC_result.csp_a}};

bbci.classifier.C= trainClassifier(fv2, opt.model);

bbci.quit_condition.marker= 255;

opt_xv= struct('SampleFcn',{{@sample_chronKFold,8}});
[loss,loss_std]= crossvalidation(BC_result.feature, opt.model, opt_xv);
bbci_log_write(data, 'CSP global (before CV!): %4.1f +/- %3.1f', 100*loss, 100*loss_std);
proc.train= {{'CSPW', @proc_cspAuto, opt.nPatterns}
             @proc_variance
             @proc_logarithm
            };
proc.apply= {{@proc_linearDerivation, '$CSPW'}
             @proc_variance
             @proc_logarithm
            };
[loss,loss_std]= crossvalidation(fv, opt.model, opt_xv, ...
                                 'Proc', proc);
bbci_log_write(data, 'CSP auto inside CV: %4.1f +/- %3.1f', ...
               100*loss, 100*loss_std);
mean_loss(ci)= loss;
std_loss(ci)= loss_std;

clear fv*

BC_result.figure_handles= figno_offset + [1 2 4];
data.result(ci)= BC_result;
cfy_fields= {'signal', 'feature', 'classifier', 'quit_condition'};
bbci_all(ci)= struct_copyFields(bbci, cfy_fields);

end  %% for ci  (class combinations)


%% --- Choose best binary combination of classes (if required) ---
%
data.all_results= data.result;
[dmy, bi]= min(mean_loss + 0.1*std_loss);
bbci= struct_copyFields(bbci, bbci_all(bi), cfy_fields);
data.result= data.all_results(bi);
data.result.class_selection_loss= [mean_loss; std_loss];

nComb= size(class_combination,1);
if nComb > 1,
  
  bbci_log_write(data, sprintf('\nCombination <%s> vs <%s> chosen.\n', ...
                               data.result.classes{:}));
  % if there exist an artifact rejection figure include it in the list 
  if ismember(3, get(0, 'Children')),
    data.result.figure_handles= [data.result.figure_handles 3];
  end
  
  % minimize figures of not-chosen class combinations
  others= setdiff(1:nComb, bi);
  h_other_figs= cat(2, data.all_results(others).figure_handles);
  set(h_other_figs, 'Visible','off');
end

%% Store settings
data.figure_handles= data.result.figure_handles;
