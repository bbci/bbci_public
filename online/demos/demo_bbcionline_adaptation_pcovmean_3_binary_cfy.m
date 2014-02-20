% DEMO_BBCIONLINE_ADAPTATION_PCOVMEAN_3_BINARY_CFY
%   The script illustrates a case of classifier adaptation (in simulated
%   online mode. The dataset contains three types of motor imagery,
%   /left hand/, /right hand/, and /feet/. On the data set, three
%   binary classifiers (L vs R, L vs F, F vs R) are adapted with the
%   supervised PCOVMEAN method, see [Vidaurre et al, 2011]. Each
%   classfier starts from a subject-independent LDA classifier. The
%   features are log band-power in two frequency bands and three channels.


BTB_memo= BTB;
BTB.MatDir= fullfile(BTB.DataDir, 'demoMat');

% Subject-independent kickstart classifier
cfy_dir= fullfile(BTB.MatDir, 'subject_independent_classifiers');
bbci= load(fullfile(cfy_dir, 'kickstart_MI_C3CzC4_9-15_15-35'));

% EEG file used of offline simulation of online processing
eeg_file= fullfile('VPkg_08_08_07', ...
                   'calibration_motorimageryVPkg');
[cnt, mrk]= file_loadMatlab(eeg_file);

% Specification for pseudo-online analysis
bbci.source.acquire_fcn= @bbci_acquire_offline;
bbci.source.acquire_param= {cnt, mrk};

bbci.log.output= 'file';
bbci.log.folder= BTB.TmpDir;
bbci.log.classifier= 1;

data= bbci_apply(bbci);


%% Evaluation: extract classifier outputs from log-file and
%   show traces of event-related classifier outputs for each combination

log_format= '%fs %s %s';
[time, cfystr, ctrlstr]= ...
    textread(data.log.filename, log_format, ...
             'delimiter','|','commentstyle','shell');
cfy= cell2mat(cellfun(@str2num, cfystr, 'UniformOutput',0));

cnt_cfy= struct('fs',25, 'x',cfy, 'clab',{{'cfy-LR','cfy-LF','cfy-FR'}});
epo_cfy= proc_segmentation(cnt_cfy, mrk, [0 5000]);
fig_set(1, 'Name','classifier outputs', 'Clf',1);
grid_plot(epo_cfy);

BTB= BTB_memo;
