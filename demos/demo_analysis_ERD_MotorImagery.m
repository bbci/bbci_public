eeg_file= fullfile(BTB.DataDir, 'demoMat', ...
                   'VPkg_08_08_07', 'calibration_motorimageryVPkg');

%% Load data
try
  [cnt, mrk, mnt] = file_loadMatlab(eeg_file);
catch
  error('You need to run ''demo_convert_ERPSpeller'' first');
end

%% Choose Electrode Montage
mnt= mnt_setGrid(mnt, 'M');

clab= {'C3','C4'};
classes = {'left','right'};
ival_erd= [-500 6000];
band_erd= [10 14];
ival_scalps= 0:750:6000;

% Bandpass to the frequency band of interest
[b,a]= butter(5, band_erd/cnt.fs*2);
cnt= proc_filt(cnt, b, a);

% Select classes 'left' and 'right'
mrk = mrk_selectClasses(mrk,classes);

% Artifact rejection based on variance criterion
mrk= reject_varEventsAndChannels(cnt, mrk, ival_erd, ...
                                 'DoBandpass', 0, ...
                                 'Verbose', 1);

epo= proc_segmentation(cnt, mrk, ival_erd);
erd_lar= proc_localAverageReference(epo, mnt, 'Radius',0.4);
erd_lar= proc_envelope(erd_lar, 'MovAvgMsec', 200);
erd_lar= proc_baseline(erd_lar, [0 750], 'trialwise', 0);
erd= proc_envelope(epo, 'MovAvgMsec', 200);
erd= proc_baseline(erd, [0 750], 'trialwise', 0);
erd_lar_r= proc_rSquareSigned(erd_lar);
erd_r= proc_rSquareSigned(erd);

fig_set(1)
H= grid_plot(erd, mnt, defopt_erps);
grid_addBars(erd_r, 'HScale',H.scale);
fig_set(2)
H= grid_plot(erd_lar, mnt, defopt_erps);
grid_addBars(erd_lar_r, 'HScale',H.scale);

fig_set(3);
H= plot_scalpEvolutionPlusChannel(erd, mnt, clab, ival_scalps, ...
                                  defopt_scalp_erp, ...
                                  'ExtrapolateToMean', 1);
grid_addBars(erd_r);

fig_set(4, 'Resize',[1 2/3]);
plot_scalpEvolutionPlusChannel(erd_r, mnt, clab, ival_scalps, defopt_scalp_r);
