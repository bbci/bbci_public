
eeg_file= fullfile(BTB.DataDir, 'demoMat', ...
    'VPai_01_11_23', 'selfpaced2sVPai');

%% Load data
[cnt, mrk, mnt] = file_loadMatlab(eeg_file);

%% Electrode Montage
grd= sprintf(['scale,_,F3,Fz,F4,_,legend\n' ...
              'FC5,FC3,FC1,FCz,FC2,FC4,FC6\n' ...
              'C5,C3,C1,Cz,C2,C4,C6\n' ...
              'CP5,CP3,CP1,CPz,CP2,CP4,CP6']);
mnt= mnt_setGrid(mnt, grd);

colOrder= [245 159 0; 0 150 200]/255;
clab= {'C3','C4'};
ival_erd= [-1000 500];
band_erd= [11 14];
ival_scalps= -800:200:200;

% Bandpass to the frequency band of interest
[b,a]= butter(5, band_erd/cnt.fs*2);
cnt= proc_filt(cnt, b, a);

% Artifact rejection based on variance criterion
mrk= reject_varEventsAndChannels(cnt, mrk, ival_erd, ...
                                 'DoBandpass', 0, ...
                                 'Verbose', 1);

epo= proc_segmentation(cnt, mrk, ival_erd);
erd_lar= proc_localAverageReference(epo, mnt, 'Radius',0.4);
erd_lar= proc_envelope(erd_lar, 'MovAvgMsec', 200);
erd_lar= proc_baseline(erd_lar, [], 'trialwise', 0);
erd= proc_envelope(epo, 'MovAvgMsec', 200);
erd= proc_baseline(erd, [], 'trialwise', 0);
erd_lar_r= proc_rSquareSigned(erd_lar);
erd_r= proc_rSquareSigned(erd);

fig_set(1)
H= grid_plot(erd, mnt, defopt_erps, 'colorOrder',colOrder);
grid_addBars(erd_r, 'HScale',H.scale);
fig_set(5)
H= grid_plot(erd_lar, mnt, defopt_erps, 'colorOrder',colOrder);
grid_addBars(erd_lar_r, 'HScale',H.scale);

fig_set(2);
H= plot_scalpEvolutionPlusChannel(erd, mnt, clab, ival_scalps, ...
                                  defopt_scalp_erp, ...
                                  'ExtrapolateToMean', 1, ...
                                  'ColorOrder',colOrder);
grid_addBars(erd_r);

fig_set(4, 'Resize',[1 2/3]);
plot_scalpEvolutionPlusChannel(erd_r, mnt, clab, ival_scalps, defopt_scalp_r);
