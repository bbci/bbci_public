%See
% Blankertz B, Lemm S, Treder MS, Haufe S, Müller KR.
% Single-trial analysis and classification of ERP components - a tutorial.
% Neuroimage, 56:814-825, 2011.
% http://dx.doi.org/10.1016/j.neuroimage.2010.06.048


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
epo= proc_segmentation(cnt, mrk, [-200 800]);

% Setting for crossvalidation
opt_xv= struct('SampleFcn', {{@sample_KFold, 10, 'Stratified',1}}, ...
               'LossFcn', @loss_rocArea);

%% Get temporal profile of discriminability using spatial features
% for spatial features, baseline correction is required
fv= proc_baseline(epo, [-200 0]);
iv= [-50 0];
loss= [];
while iv(2)<=800,
  ff= proc_selectIval(fv, iv);
  ff= proc_meanAcrossTime(ff);
  loss= [loss, crossvalidation(ff, @train_RLDAshrink, opt_xv)];
  iv= iv + 10;
end
fig_set(1, 'clf',1);
plot(linspace(0, iv(2), length(loss), 1-loss);
xlabel('time  [ms]');
ylabel('accuracy  [auc]');

%% Get spatial profile of discriminability using temporal features
fv= proc_selectIval(epo, [0 800]);
loss= [];
for ii= 1:length(fv.clab),
  ff= proc_selectChannels(fv, ii);
  loss(ii)= crossvalidation(ff, @train_RLDAshrink, opt_xv);
end
fig_set(2, 'clf',1);
plot_scalp(mnt, 1-loss, 'CLim','range', 'Colormap', cmap_whitered(31));
% ?how to put the label 'accuracy  [auc]' to the colorbar in new Matlab?
