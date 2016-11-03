eeg_file= fullfile(BTB.DataDir, 'Mat', 'OV/mvep/Okba/27_10_2016', ...
                   'erp_350_350_3');

% Load data
try
  [cnt, mrk, mnt] = file_loadMatlab(eeg_file);
catch
  error('file not found');
end

% Define some settings
disp_ival= [-200 1000];
ref_ival= [-200 0];
clab= {'Cz','PO7'};
colOrder= [1 0 1; 0.4 0.4 0.4];

% Apply highpass filter to reduce drifts
b= procutil_firlsFilter(0.5, cnt.fs);
cnt= proc_filtfilt(cnt, b);

% Segmentation
epo= proc_segmentation(cnt, mrk, disp_ival);

% Baseline subtraction, and calculation of a measure of discriminability
epo= proc_baseline(epo, ref_ival);
epo_r= proc_rSquareSigned(epo);

% Select some discriminative intervals, with constraints to find N2, P2, P3 like components.
fig_set(3);
constraint= ...
      {{-1, [100 300], {'Oz','PO7-8'}, [50 300]}, ...
       {1, [200 350], {'P3-4','Pz'}, [200 400]}, ...
       {1, [400 500], {'P3-4','Cz'}, [350 600]}};
[ival_scalps, nfo]= ...
    procutil_selectTimeIntervals(epo_r, 'Visualize', 1, 'VisuScalps', 1, ...
                                 'Title', util_untex(eeg_file), ...
                                 'Clab',{'not','E*'}, ...
                                 'Constraint', constraint);
%printFigure('r_matrix', [18 13]);
ival_scalps= visutil_correctIvalsForDisplay(ival_scalps, 'Fs',epo.fs);


fig_set(1)
H= grid_plot(epo, mnt, defopt_erps, 'ColorOrder',colOrder);
% grid_addBars(epo_r);
% grid_addBars(epo_r, 'HScale',H.scale);
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








