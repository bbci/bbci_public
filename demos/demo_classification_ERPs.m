eeg_file= fullfile(BTB.DataDir, 'demoMat', 'VPiac_10_10_13', ...
                   'calibration_CenterSpellerMVEP_VPiac');

% Load data
try
  [cnt, mrk, mnt] = file_loadMatlab(eeg_file);
catch
  error('You need to run ''demo_convert_ERPSpeller'' first');
end

% Exclude possible EOG ro EMG channels
cnt= proc_selectChannels(cnt, 'not', 'E*');

% Segmentation
epo= proc_segmentation(cnt, mrk, [-100 800]);

% Select discriminative time intervals
epo_r= proc_rSquareSigned(epo);
ival_cfy= procutil_selectTimeIntervals(epo_r);

% Alternatively use fixed intervals
%ival_cfy= [150:20:250, 300:50:750];

% Feature extraction  (spatio-temporal features)
fv= proc_baseline(epo, [-100 0]);
fv= proc_jumpingMeans(fv, ival_cfy);

%% Cross-validation with Shrinkage-LDA:

% stratified 10-fold cross-validation
crossvalidation(fv, @train_RLDAshrink, ...
                    'SampleFcn', {@sample_KFold, 10, 'Stratified',1})

% leave-one-out validation
%crossvalidation(fv, @train_RLDAshrink, 'SampleFcn', @sample_leaveOneOut)

% validation with chronological splits
%crossvalidation(fv, @train_RLDAshrink, 'SampleFcn', {@sample_chronKFold, 8})
