eeg_file= fullfile(BTB.DataDir, 'demoMat', 'VPiac_10_10_13', ...
                   'calibration_CenterSpellerMVEP_VPiac');

% Load data
try
  [cnt, mrk, mnt] = file_loadMatlab(eeg_file);
catch
  error('You need to run ''demo_convert_ERPSpeller'' first');
end

% Define some settings
disp_ival= [-200 1000];
ref_ival= [-200 0];
crit_maxmin= 70;
crit_ival= [100 800];
crit_clab= {'F9,z,10','AF3,4'};
clab= {'Cz','PO7'};
colOrder= [1 0 1; 0.4 0.4 0.4];

% Apply highpass filter to reduce drifts
b= procutil_firlsFilter(0.5, cnt.fs);
cnt= proc_filtfilt(cnt, b);
  
% Artifact rejection based on variance criterion
mrk= reject_varEventsAndChannels(cnt, mrk, disp_ival, 'verbose', 1);

% Segmentation
epo= proc_segmentation(cnt, mrk, disp_ival);
  
% Artifact rejection based on maxmin difference criterion on frontal chans
[epo iArte] = proc_rejectArtifactsMaxMin(epo, crit_maxmin, 'Clab',crit_clab, ...
                                'Ival',crit_ival, 'Verbose',1);

% Baseline subtraction, and calculation of a measure of discriminability
epo= proc_baseline(epo, ref_ival);
epo_r= proc_rSquareSigned(epo);

% Select some discriminative intervals, with constraints to find N2, P2, P3 like components.
fig_set(3);
constraint= ...
      {{-1, [100 300], {'I#','O#','PO7,8','P9,10'}, [50 300]}, ...
       {1, [200 350], {'P3-4','CP3-4','C3-4'}, [200 400]}, ...
       {1, [400 500], {'P3-4','CP3-4','C3-4'}, [350 600]}};
[ival_scalps, nfo]= ...
    procutil_selectTimeIntervals(epo_r, 'Visualize', 1, 'VisuScalps', 1, ...
                                 'Title', util_untex(eeg_file), ...
                                 'Clab',{'not','E*'}, ...
                                 'Constraint', constraint);
%printFigure('r_matrix', [18 13]);
ival_scalps= visutil_correctIvalsForDisplay(ival_scalps, 'Fs',epo.fs);

fig_set(1)
H= grid_plot(epo, mnt, defopt_erps, 'ColorOrder',colOrder);
grid_addBars(epo_r, 'HScale',H.scale);
%printFigure(['erp'], [19 12]);

fig_set(2);
H= plot_scalpEvolutionPlusChannel(epo, mnt, clab, ival_scalps, ...
                                  defopt_scalp_erp, ...
                                  'ColorOrder',colOrder);
grid_addBars(epo_r);
%printFigure(['erp_topo'], [20  4+5*size(epo.y,1)]);

fig_set(4, 'Resize',[1 2/3]);
plot_scalpEvolutionPlusChannel(epo_r, mnt, clab, ival_scalps, defopt_scalp_r);
%printFigure(['erp_topo_r'], [20 9]);
