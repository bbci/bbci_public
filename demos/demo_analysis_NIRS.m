BTB.MatDir= fullfile(BTB.DataDir, 'demoMat');
filename= fullfile('VPean_10_07_26', 'NIRS', 'real_movementVPean');

%% Load data
[cnt, mrk, mnt] = file_loadNIRSMatlab(filename, 'Signal','oxy');

%% define classes according to makers
stimDef= {1,2;'left','right'};
mrk = mrk_defineClasses(mrk, stimDef);

%% intervalls for display and segmentation, and fequencies for filter
ival_base=  [-1000 0];
ival_epo= [-1000 15000];
ival_scalps= [0:2500:12500];
clab=[];

%% segmentation and baseline correction
epo= proc_segmentation(cnt, mrk, ival_epo);
epo= proc_baseline(epo, ival_base);

%% r-values
epo_r= proc_rSquareSigned(epo);

%% display
fig_set(1)
H= grid_plot(epo, mnt, defopt_erps);
grid_addBars(epo_r, 'HScale',H.scale);

fig_set(2);
H= plot_scalpEvolution(epo, mnt, ival_scalps, ...
                       defopt_scalp_erp, ...
                       'ExtrapolateToMean', 1);

fig_set(4, 'Resize',[1 0.5]);
H= plot_scalpEvolution(epo_r, mnt, ival_scalps, ...
                       defopt_scalp_r);
