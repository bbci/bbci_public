# Some Practical Examples of how to use the BBCI Toolbox

Here we show example scripts of how to apply the BBCI Toolbox for typical
offline analysis scenarios. 

### Table of Contents

* [Convert](#Convert) - _Conversion of EEG data from BrainVision format to Matlab_
* [ERP Analysis](#ErpAnalysis) - _Analysis of Event-Related Potentials (ERPs)_
* [Grand Average ERP Analysis](#GrandAverageErp) - _ERP analysis with multiple participants (including robust statistics)_
* [Spectral Analysis](#SpectralAnalsis) - _Event-related spectral Analysis_
* [ERD/ERS Analysis](#ErdAnalysis) - _Analysis of event-related modulations of brain rythms_
* [NIRS Analysis](#NirsAnalysis) - _Analysis of Near-Infrared Spectroscopy (NIRS) data)_
* more to come ...

---

## Conversion of EEG data from BrainVision format to Matlab  <a id="Convert"></a>

Sometimes it is convinient to convert the raw data files to Matlab format and do
some preprocessing before performing different kinds of analysis. An example of
such preprocessing can be re-referencing or the (re-)combination of stimulus
markers.

The following script illustrates how to do the conversion.

```matlab
BTB_memo= BTB;
BTB.RawDir= fullfile(BTB.DataDir, 'demoRaw');
BTB.MatDir= fullfile(BTB.DataDir, 'demoMat');

% add more to the list if you want to do it in a row
subdir_list= {'VPiac_10_10_13'};
% you could have more files also
basename_list= {'calibration_CenterSpellerMVEP_'};

Fs = 100; % new sampling rate
% definition of classes based on markers 
stimDef= {[31:46], [11:26];
          'target','nontarget'};


% load raw files (with filtering), define classes and montage,
% and save in matlab format
for k= 1:length(subdir_list);
 for ib= 1:length(basename_list),
  subdir= subdir_list{k};
  sbj= subdir(1:find(subdir=='_',1,'first')-1);
  file= fullfile(subdir, [basename_list{ib} sbj]);
  fprintf('converting %s\n', file)
  % header of the raw EEG files
  hdr = file_readBVheader(file);
  
  % low-pass filter
  Wps = [42 49]/hdr.fs*2;
  [n, Ws] = cheb2ord(Wps(1), Wps(2), 3, 40);
  [filt.b, filt.a]= cheby2(n, 50, Ws);
  % load raw data, downsampling is done while loading (after filtering)
  [cnt, mrk_orig] = file_readBV(file, 'Fs',Fs, 'Filt',filt);

  % Re-referencing to linked-mastoids
  %   (data was referenced to A2 during acquisition)
  A = eye(length(cnt.clab));
  iref2 = util_chanind(cnt.clab, 'A1');
  A(iref2,:) = -0.5;
  A(:,iref2) = [];
  cnt = proc_linearDerivation(cnt, A);
  
  % create mrk and mnt
  mrk= mrk_defineClasses(mrk_orig, stimDef);
  mrk.orig= mrk_orig;
  mnt= mnt_setElectrodePositions(cnt.clab);
  mnt= mnt_setGrid(mnt, 'M+EOG');
  
  % save in matlab format
  file_saveMatlab(file, cnt, mrk, mnt, 'Vars','hdr');
 end
end

BTB= BTB_memo;
```


## Analysis of Event-Related Potentials (ERPs)   <a id="ErpAnalysis"></a>

This script shows the analysis of Event-Related Potentials. We will work data
that has been converted to Matlab format as outlined in the practical example
above.

```matlab
BTB_memo= BTB;
BTB.MatDir= fullfile(BTB.DataDir, 'demoMat');
file= fullfile('VPiac_10_10_13', ...
               'calibration_CenterSpellerMVEP_VPiac');

% Define some settings
disp_ival= [-200 1000];
ref_ival= [-200 0];
crit_maxmin= 70;
crit_ival= [100 800];
crit_clab= {'F9,z,10','AF3,4'};
clab= {'Cz','PO7'};
colOrder= [1 0 1; 0.4 0.4 0.4];

% Load data
try
  [cnt, mrk, mnt] = file_loadMatlab(file);
catch
  error('You need to run ''demo_convert_ERPSpeller'' first');
end


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
                                 'Title', util_untex(file), ...
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

BTB= BTB_memo;
```


## Grand Average ERP Analysis   <a id="GrandAverageErp"></a>

In this example script we show how to conduct a Grand Average ERP analysis
across several subjects. 

```matlab
files = {
    fullfile('VPibv_10_11_02','calibration_CenterSpellerMVEP_VPibv')
    fullfile('VPibq_10_09_24','calibration_CenterSpellerMVEP_VPibq')
    fullfile('VPiac_10_10_13','calibration_CenterSpellerMVEP_VPiac')
    };


%% Define some settings
disp_ival= [-200 1000];
ref_ival= [-200 0];
crit_maxmin= 70;
crit_ival= [100 800];
crit_clab= {'F9,z,10','AF3,4'};
clab= {'Cz','PO7'};
colOrder= [1 0 1; 0.4 0.4 0.4];

%% load all data sets
nsub = length(files);
for isub = 1:nsub
    file = files{isub};
    file= fullfile(BTB.DataDir, 'demoMat', file);
    
    %% Load data
    fprintf('loading %s \n', file)
    
    [cnt, mrk, mnt] = file_loadMatlab(file);
        
    %% Apply highpass filter to reduce drifts
    b= procutil_firlsFilter(0.5, cnt.fs);
    cnt= proc_filtfilt(cnt, b);
    
    %% Artifact rejection based on variance criterion
    mrk= reject_varEventsAndChannels(cnt, mrk, disp_ival, 'verbose', 1);
    
    %% Segmentation
    epo= proc_segmentation(cnt, mrk, disp_ival);
    
    %% Artifact rejection based on maxmin difference criterion on frontal chans
    [epo iArte] = proc_rejectArtifactsMaxMin(epo, crit_maxmin, 'Clab',crit_clab, ...
        'Ival',crit_ival, 'Verbose',1);
    
    %% Baseline subtraction, and calculation of a measure of discriminability
    epo= proc_baseline(epo, ref_ival);
    
    epos_av{isub} = proc_average(epo, 'Stats', 1);
    
    % three different but almost equivalent ways to make statistics about class differences
    epos_diff{isub} = proc_classmeanDiff(epo, 'Stats', 1);
    epos_r{isub} = proc_rSquareSigned(epo, 'Stats', 1);
    epos_auc{isub} = proc_aucValues(epo, 'Stats', 1);
    
end

%% grand average
epo_av = proc_grandAverage(epos_av, 'Average', 'INVVARweighted', 'Stats', 1, 'Bonferroni', 1, 'Alphalevel', 0.01);
epo_r = proc_grandAverage(epos_r, 'Average', 'INVVARweighted', 'Stats', 1, 'Bonferroni', 1, 'Alphalevel', 0.01);
epo_diff = proc_grandAverage(epos_diff, 'Average', 'INVVARweighted', 'Stats', 1, 'Bonferroni', 1, 'Alphalevel', 0.01);
epo_auc = proc_grandAverage(epos_auc, 'Average', 'INVVARweighted', 'Stats', 1, 'Bonferroni', 1, 'Alphalevel', 0.01);

%% Select some discriminative intervals, with constraints to find N2, P2, P3 like components.
constraint= ...
    {{-1, [100 300], {'I#','O#','PO7,8','P9,10'}, [50 300]}, ...
    {1, [200 350], {'P3-4','CP3-4','C3-4'}, [200 400]}, ...
    {1, [400 500], {'P3-4','CP3-4','C3-4'}, [350 600]}};
[ival_scalps, nfo]= ...
    procutil_selectTimeIntervals(epo_r, 'Visualize', 0, 'VisuScalps', 1, ...
    'Title', util_untex(file), ...
    'Clab',{'not','E*'}, ...
    'Constraint', constraint);
%printFigure('r_matrix', [18 13]);
ival_scalps= visutil_correctIvalsForDisplay(ival_scalps, 'fs',epo.fs);

%% plot classwise grand-average ERPs
fig_set(1);
H= plot_scalpEvolutionPlusChannel(epo_av, mnt, clab, ival_scalps, defopt_scalp_erp, ...
    'ColorOrder',colOrder);
grid_addBars(epo_r);
%printFigure(['erp_topo'], [20  4+5*size(epo.y,1)]);

%% plot difference of the class means
fig_set(2, 'Resize',[1 2/3]);
plot_scalpEvolutionPlusChannel(epo_diff, mnt, clab, ival_scalps, defopt_scalp_r);
%printFigure(['erp_topo_r'], [20 9]);

% plot signed log10 p-values of the null hypothesis
% that the difference of the class means is zero
% interpretation: abs(sgnlogp) > 1   <-->  p < 0.1
%                 abs(sgnlogp) > 2   <-->  p < 0.01
%                 abs(sgnlogp) > 3   <-->  p < 0.001 , and so on
fig_set(3, 'Resize',[1 2/3]);
epo_diff_sgnlogp = epo_diff;
epo_diff_sgnlogp.x = epo_diff_sgnlogp.sgnlogp;
epo_diff_sgnlogp.yUnit = 'sgnlogp';
plot_scalpEvolutionPlusChannel(epo_diff_sgnlogp, mnt, clab, ival_scalps, defopt_scalp_r);
%printFigure(['erp_topo_r'], [20 9]);

%% now plot differences again, with all insignificant results set to zero
epo_diff.x = epo_diff.x.*epo_diff.sigmask;
fig_set(4, 'Resize',[1 2/3]);
plot_scalpEvolutionPlusChannel(epo_diff, mnt, clab, ival_scalps, defopt_scalp_r);
```


## Event-Related Spectral Analysis   <a id="SpectralAnalysis"></a>

This script shows how to perform spectral analysis of data related to events
(e.g. stimulus triggers or response markers). Here we use data from an
experiment in which self-paced finger tapping was performed and analyse the
spectra around tapping events (i.e. keyboard hits). 

```matlab
eeg_file= fullfile(BTB.DataDir, 'demoMat', ...
    'demo_Pavel_01_11_23', 'selfpaced2sPavel');

%% Load data
[cnt, mrk, mnt] = file_loadMatlab(eeg_file);


%% Electrode Montage
grd= sprintf(['EOGh,_,F3,Fz,F4,_,EOGv\n' ...
              'FC5,FC3,FC1,FCz,FC2,FC4,FC6\n' ...
              'C5,C3,C1,Cz,C2,C4,C6\n' ...
              'CP5,CP3,CP1,CPz,CP2,CP4,CP6\n' ...
              'EMGl,scale,O1,_,O2,legend,EMGr']);
mnt= mnt_setGrid(mnt, grd);

colOrder= [245 159 0; 0 150 200]/255;
opt_grid_spec= defopt_spec('xTickAxes','CPz', ...
                           'colorOrder',colOrder);

ival_spec= [-1000 0];  % Pre-movement interval: investigate motor-preparation
band_list= [7 11; 11 14; 20 24; 26 36];
clab= {'C3','C4'};
winlen= cnt.fs;    % length of FFT in proc_spectrum: 1s. To investigate spectra of short
                   % epochs taking 0.5s is also possible -> frequency resolution 2Hz.

% Artifact rejection based on variance criterion
fig_set(1);
mrk= reject_varEventsAndChannels(cnt, mrk, ival_spec, 'visualize',1, 'verbose', 1);

% Segmentation
spec= proc_segmentation(cnt, mrk, ival_spec);
spec_lar= proc_localAverageReference(spec, mnt, 'radius',0.4);
spec_lar= proc_spectrum(spec_lar, [5 40], kaiser(winlen,2));
spec= proc_spectrum(spec, [5 40], kaiser(winlen,2));
spec_r= proc_rSquareSigned(spec);
spec_r= proc_selectChannels(spec_r, 'not','E*');
spec_lar_r= proc_rSquareSigned(spec_lar);
spec_lar_r= proc_selectChannels(spec_lar_r, 'not','E*');

fig_set(1);
H= grid_plot(spec, mnt, opt_grid_spec,'XUnit', spec.xUnit, 'YUnit', spec.yUnit)
%grid_markIval(band_erd);     % to shade a certain frequency band
grid_addBars(spec_r, 'HScale',H.scale);

fig_set(2);
H= grid_plot(spec_lar, mnt, opt_grid_spec, 'XUnit',spec_lar.xUnit,'YUnit',spec_lar.yUnit);
grid_addBars(spec_lar_r, 'HScale',H.scale);

fig_set(3);
H= plot_scalpEvolutionPlusChannel(spec, mnt, clab, band_list, ...
                             defopt_scalp_power, ...
                             'ColorOrder',colOrder, ...
                             'ScalePos','horiz', ...
                             'GlobalCLim',0,...
                             'XUnit', spec.xUnit, 'YUnit', spec.yUnit);
grid_addBars(spec_r);

fig_set(4, 'Resize',[1 2/3]);
plot_scalpEvolutionPlusChannel(spec_r, mnt, clab, band_list, defopt_scalp_r,...
    'XUnit', spec_r.xUnit, 'YUnit', spec_r.yUnit);


%% Do the same with subtracting the spectrum in a reference time interval
% Here we use a post-movement interval.
ref_ival= [200 1200];

mrk_ref= mrk;
mrk_ref.y= ones(1, length(mrk_ref.time));
mrk_ref.className= {'ref'};
mrk_ref= reject_varEventsAndChannels(cnt, mrk_ref, ref_ival);
spec_baseline= proc_segmentation(cnt, mrk_ref, ref_ival);
spec_baseline= proc_spectrum(spec_baseline, [5 40], kaiser(winlen,2));
spec_baseline= proc_average(spec_baseline);
spec_ref= proc_subtractReferenceClass(spec, spec_baseline); % here the power is devided by power in spec_baseline, not subtracted!

fig_set(5);
H= plot_scalpEvolutionPlusChannel(spec_ref, mnt, clab, band_list, ...
                             defopt_scalp_power, ...
                             'ColorOrder',colOrder,'XUnit', spec.xUnit, 'YUnit', spec.yUnit);
grid_addBars(spec_r);
```


## Analysis of event-related modulations of brain rythms (ERD/ERS)   <a id="ErdAnalysis"></a>

```matlab

eeg_file= fullfile(BTB.DataDir, 'demoMat', ...
    'demo_Pavel_01_11_23', 'selfpaced2sPavel');

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

```


## Analysis of NIRS data   <a id="NirsAnalysis"></a>

This example shows how to identify taks-related difference in NIRS data.

```matlab
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

```

