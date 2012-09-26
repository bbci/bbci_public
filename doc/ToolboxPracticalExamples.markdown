Documentation: Some Practical Examples of how to use the BBCI Toolbox
=====================================================================

* * * * *

**UNDER CONSTRUCTION**

* * * * *

### Table of Contents

-   ERP Analysis: <a href="#ERP-Analysis">ERP Analysis</a>

-   Event-Related Spectral Analysis: <a href="#Spectral-Analysis">Spectral Analysis</a>


-   Long-Term Spectral Analysis:<a href="#Spectral-Analysis-of-Blocks">Spectral Analysis of Blocks</a>


-   ERD/ERS Analysis: <a href="#ERD-Analysis">ERD Analysis</a>

-   more to come...

### ERP Analysis <a id="ERP-Analysis"></a>



	   1 file= 'VPibv_10_11_02/CenterSpellerMVEP_VPibv';
	   2 [cnt, mrk, mnt]= eegfile_loadMatlab(file);
	   3 
	   4 % Define some settings
	   5 disp_ival= [-200 1000];
 	   6 ref_ival= [-200 0];
 	   7 crit_maxmin= 70;
	   8 crit_ival= [100 800];
	   9 crit_clab= {'F9,z,10','AF3,4'};	
	 10 clab= {'Cz','PO7'};
	 11 colOrder= [1 0 1; 0.4 0.4 0.4];
	 12 
 	 13 % Apply highpass filter to reduce drifts
 	 14 b= procutil_firlsFilter(0.5, cnt.fs);
 	 15 cnt= proc_filtfilt(cnt, b);
 	 16   
 	 17 % Artifact rejection based on variance criterion
 	 18 mrk= reject_varEventsAndChannels(cnt, mrk, disp_ival, 'verbose', 1);
 	 19 
 	 20 % Segmentation
 	 21 epo= cntToEpo(cnt, mrk, disp_ival);
 	 22   
 	 23 % Artifact rejection based on maxmin difference criterion on frontal chans
 	 24 epo= proc_rejectArtifactsMaxMin(epo, crit_maxmin, ...
 	 25             'clab',crit_clab, 'ival',crit_ival, 'verbose',1);
 	 26 
 	 27 % Baseline subtraction, and calculation of a measure of discriminability
 	 28 epo= proc_baseline(epo, ref_ival);
 	 29 epo_r= proc_r_square_signed(epo);
 	 30 
 	 31 % Select some discriminative intervals, with constraints to find N2, P2, P3 like components.
 	 32 fig_set(1);
 	 33 constraint= ...
 	 34       {{-1, [100 300], {'I#','O#','PO7,8','P9,10'}, [50 300]}, ...
 	 35        {1, [200 350], {'P3-4','CP3-4','C3-4'}, [200 400]}, ...
 	 36        {1, [400 500], {'P3-4','CP3-4','C3-4'}, [350 600]}};
 	 37 [ival_scalps, nfo]= ...
 	 38     select_time_intervals(epo_r, 'visualize', 1, 'visu_scalps', 1, ...
 	 39                           'title', untex(file), ...
 	 40                           'clab',{'not','E*'}, ...
 	 41                           'constraint', constraint);
 	 42 printFigure('r_matrix', [18 13]);
 	 43 ival_scalps= visutil_correctIvalsForDisplay(ival_scalps, 'fs',epo.fs);
 	 44 
 	 45 fig_set(3)
 	 46 H= grid_plot(epo, mnt, defopt_erps, 'colorOrder',colOrder);
 	 47 grid_addBars(epo_r, 'h_scale',H.scale);
 	 48 printFigure(['erp'], [19 12]);
 	 49 
 	 50 fig_set(2);
 	 51 H= scalpEvolutionPlusChannel(epo, mnt, clab, ival_scalps, defopt_scalp_erp2, ...
 	 52                              'colorOrder',colOrder);
 	 53 grid_addBars(epo_r);
 	 54 printFigure(['erp_topo'], [20  4+5*size(epo.y,1)]);
 	 55 
 	 56 fig_set(4, 'shrink',[1 2/3]);
 	 57 scalpEvolutionPlusChannel(epo_r, mnt, clab, ival_scalps, defopt_scalp_r2);
 	 58 printFigure(['erp_topo_r'], [20 9]);
 	 59 

Even in this very basic ERP analysis, there are several steps, in which
the choice of processing can have quite a big impact on the results, but
nevertheless, the correct choice is not clear to us (maybe we will find
out a recommendable choice at some point).

1.  Highpass filter (lines 14-15). Highpass filtering may be beneficial
    to reduce the impact of drifts. But the choice of the filter has
    quite some impact on the ERPs, in particular, the later ERPs.
    Alternatives are
    `proc_subtractMovingAverage(cnt, 1500, 'centered', 'sinus')`,
    other highpass filters, or no highpass filtering at all. Also
    bandpass filtering is an alternative (e.g. [0.5 30]), but typically
    the lowpass filtering is not required since high frequency are
    dampened also by the normal ERP averaging across trials.

2.  Baseline correction (line 28). For the ERP themselves the choice of
    baseline correction does not matter. They stay the same. But for the
    measure for discriminability (e.g.
    r^2-values) it  may  have  a  big  impact.  In  this  example,  baseline  correction  is  performed  on  a  trialwise  basis.  This  way  it  is  done  for  online  experiments.  For  the  ERP  analysis  this  may  be  have  the  disturbing  consequency,  that  the  r^2-values
    in/near the baseline interval can become spuriously high, since the
    trial-to-trial variance is artificially reduced. Alternatives are to
    subtract the across-trials average of the baseline (option
    `'trialwise',0` in `proc_baseline`) or to
    subtract the classwise average of the baseline (option
    `'classwise',1` in `proc_baseline`).

3.  Measure for discriminability (line 29). Choices are, e.g., signed
    r^2, t-values, p-values, AUC-score.
4.  If, in an oddball-like paradigm, stimuli are presented in a fast
    sequence, it might be beneficial for the ERP analysis to constrain
    the occurrence of target stimuli within the time interval of
    investigation. This has to be done as first operation for marker
    processing (i.e., *before* the artifact rejection in line 18). To
    exclude target occurrences before/after the event at t=0, use the
    function `mrk_selectTargetDist`. E.g., to exclude targets
    to be one of the 3 preceding and the 2 subsequent stimuli, use
    ` mrk= mrk_selectTargetDist(mrk, [3 2]); `. Defining different
    constraints for target and nontarget events is also possible.

### Event-Related Spectral Analysis  <a id="Spectral-Analysis"></a>


	  1 file= 'Pavel_01_11_23/selfpaced2sPavel';
	  2 [cnt, mrk, mnt]= eegfile_loadMatlab(file);
	  3 
	  4 colOrder= [245 159 0; 0 150 200]/255;
	  5 opt_grid_spec= defopt_spec('xTickAxes','O2', ...
 	  6                            'colorOrder',colOrder);
	  7 
	  8 ival_spec= [-1000 0];  % Pre-movement interval: investigate motor-preparation
	  9 band_list= [7 11; 11 14; 20 24; 26 36];
	10 clab= {'C3','C4'};
	11 winlen= cnt.fs;    % length of FFT in proc_spectrum: 1s. To investigate spectra of short
	12                    % epochs taking 0.5s is also possible -> frequency resolution 2Hz.
	13 
	14 % Artifact rejection based on variance criterion
	15 mrk= reject_varEventsAndChannels(cnt, mrk, ival_spec, 'verbose', 1);
	16 
	17 % Segmentation
 	18 spec= cntToEpo(cnt, mrk, ival_spec);
	19 spec_lar= proc_localAverageReference(spec, mnt, 'radius',0.4);
	20 spec_lar= proc_spectrum(spec_lar, [5 40], kaiser(winlen,2));
	21 spec= proc_spectrum(spec, [5 40], kaiser(winlen,2));
	22 spec_r= proc_r_square_signed(spec);
	23 spec_lar_r= proc_r_square_signed(spec_lar);
	24 
	25 fig_set(1);
	26 H= grid_plot(spec, mnt, opt_grid_spec);
	27 %grid_markIval(band_erd);     % to shade a certain frequency band
	28 grid_addBars(spec_r, 'h_scale',H.scale);
	29 
	30 fig_set(5);
	31 H= grid_plot(spec_lar, mnt, opt_grid_spec);
	32 grid_addBars(spec_lar_r, 'h_scale',H.scale);
	33 
	34 fig_set(2);
	35 H= scalpEvolutionPlusChannel(spec, mnt, clab, band_list, ...
	36                              defopt_scalp_power2, ...
	37                              'colorOrder',colOrder, ...
	38                              'scalePos','horiz', ...
 	39                              'globalCLim',0);
	40 grid_addBars(spec_r);
	41 
 	42 fig_set(4, 'shrink',[1 2/3]);
	43 scalpEvolutionPlusChannel(spec_r, mnt, clab, band_list, defopt_scalp_r2);
	44 
	45 
	46 %% Do the same with subtracting the spectrum in a reference time interval
	47 % Here we use a post-movement interval.
	48 ref_ival= [200 1200];
	49 
	50 mrk_ref= mrk;
	51 mrk_ref.y= ones(1, length(mrk_ref.pos));
	52 mrk_ref.className= {'ref'};
	53 mrk_ref= reject_varEventsAndChannels(cnt, mrk_ref, ref_ival);
	54 spec_baseline= makeEpochs(cnt, mrk_ref, ref_ival);
	55 spec_baseline= proc_spectrum(spec_baseline, [5 40], kaiser(winlen,2));
	56 spec_baseline= proc_average(spec_baseline);
	57 spec_ref= proc_subtractReferenceClass(spec, spec_baseline);
	58 
	59 fig_set(6);
	60 H= scalpEvolutionPlusChannel(spec_ref, mnt, clab, band_list, ...
	61                              defopt_scalp_power2, ...
	62                              'extrapolate', 0, ...
	63                              'colorOrder',colOrder);
	64 grid_addBars(spec_r);
	65 

### Long-Term Spectral Analysis <a id="Spectral-Analysis-of-Blocks"></a>



	   1 file= 'VPgce_11_02_08/relaxVPgce';
	   2 [cnt, mrk, mnt]= eegfile_loadMatlab(file);
	   3 
	   4 band_list= [4 7; 7 10; 10 13; 13 26];
	   5 
	   6 % get information about starting and stopping time of 'eyes open' and
	   7 % 'eyes closed' phases:
	   8 blk1= blk_segmentsFromMarkers(mrk, ...
	   9                               'start_marker','eyes_closed', ...
	  10                               'end_marker','stop');
	  11 blk2= blk_segmentsFromMarkers(mrk, ...	
	  12                               'start_marker','eyes_open', ...
	  13                               'end_marker','stop');
	  14 blk= blk_merge(blk1, blk2, 'className',{'eyes closed','eyes open'});
	  15 
	  16 % Generate a marker structure which has markers every 1000msec with in
	  17 % blocks of 'eyes-open' and 'eyes-closed'.
	  18 mkk= mrk_evenlyInBlocks(blk, 1000);
	  19 
	  20 % Alternatively, this code can be used to save memory. Here the new cnt
	  21 % will consist of a concatenation of the blocks that are defined in 'blk',
 	  22 % i.e., parts which do not belong to any block are left out. The structure
	  23 % 'blkcnt' is the block structure corresponding to the new 'cnt'.
	  24 %[cnt, blkcnt]= proc_concatBlocks(cnt, blk);
	  25 %mkk= mrk_evenlyInBlocks(blkcnt, 1000);
	  26 
	  27 fig_set(1);
	  28 [mkk, rClab]= reject_varEventsAndChannels(cnt, mkk, [0 999], ...
	  29                                           'visualize', 1);
	  30 printFigure(['artifact_rejection'], [19 12]);
	  31 
	  32 % Spectra are calculated on raw channels, and on spatially filtered channels.
	  33 % Laplacian filters can be used if the area of interest is centrally located.
	  34 % At the border of the cap (e.g. for visual cortex), local average reference 
	  35 % often works better. For the grid plot, spatially filtered channels are mostly
	  36 % preferable, but for scalp topographies it is better to use spectra from
	  37 % raw channels.
	  38 spec= cntToEpo(cnt, mkk, [0 1000], 'mtsp', 'before');
	  39 spec_lap= proc_localAverageReference(spec, mnt, 'radius',0.6);
	  40 spec_lap= proc_spectrum(spec_lap, [1 40], kaiser(cnt.fs,2));
	  41 spec= proc_spectrum(spec, [1 40], kaiser(cnt.fs,2));
	  42 spec_r= proc_r_square_signed(spec);
	  43 spec_lap_r= proc_r_square_signed(spec_lap);
	  44 
	  45 H= grid_plot(spec, mnt, defopt_spec);
	  46 grid_addBars(spec_r, 'h_scale',H.scale);
	  47 printFigure(['spec'], [24 16]);
	  48 
	  49 H= grid_plot(spec_lap, mnt, defopt_spec);
	  50 grid_addBars(spec_lap_r, 'h_scale',H.scale);
	  51 printFigure(['spec_lap'], [24 16]);
	  52 
	  53 fig_set(2);
	  54 H= scalpEvolutionPlusChannel(spec, mnt, 'Pz', band_list, ...
         	 55                              defopt_scalp_power2, ...
	  56                              'scalePos','horiz', ...	
	  57                              'globalCLim',0);
	  58 grid_addBars(spec_r, 'rectify',1, 'vpos',1);
	  59 printFigure(['spec_topo'], [24 15]);
	  60 
	  61 fig_set(4, 'shrink',[1 2/3]);
	  62 spec_r.className= {sprintf(' pm r^2 (EC,EO)')};
	  63 scalpEvolutionPlusChannel(spec_r, mnt, 'Pz', band_list, ...
	  64                           defopt_scalp_r2);
	  65 printFigure(['spec_topo_r'], [24 10]);
 	 66 

### ERD/ERS Analysis <a id="ERD-Analysis"></a>

Investigating the time course of band-power, i.e., ERD/ERS curves is
pretty much like ERP analysis, but with calculating the envelope of the
band-pass filtered signals before:



	   1 file= 'Pavel_01_11_23/selfpaced2sPavel';
	   2 [cnt, mrk, mnt]= eegfile_loadMatlab(file, 'clab',{'not','E*'});
	   3 
	   4 colOrder= [245 159 0; 0 150 200]/255;
	   5 ival_erd= [-1000 500];
	   6 band_erd= [11 14];
	   7 ival_scalps= -800:200:200;
	   8 
	   9 % Bandpass to the frequency band of interest
	  10 [b,a]= butter(5, band_erd/cnt.fs*2);
	  11 cnt= proc_filt(cnt, b, a);
	  12 
	  13 % Artifact rejection based on variance criterion
	  14 mrk= reject_varEventsAndChannels(cnt, mrk, ival_erd, ...
	  15                                  'do_bandpass', 0, ...
	  16                                  'verbose', 1);
	  17 
	  18 epo= cnttoEpo(cnt, mrk, ival_erd);
	  19 erd_lar= proc_localAverageReference(epo, mnt, 'radius',0.4);
	  20 erd_lar= proc_envelope(erd_lar, 'ma_msec', 200);
	  21 erd_lar= proc_baseline(erd_lar, [], 'trialwise', 0);
	  22 erd= proc_envelope(epo, 'ma_msec', 200);
	  23 erd= proc_baseline(erd, [], 'trialwise', 0);
	  24 erd_lar_r= proc_r_square_signed(erd_lar);
	  25 erd_r= proc_r_square_signed(erd);
	  26 
	  27 fig_set(1)
	  28 H= grid_plot(erd, mnt, defopt_erps, 'colorOrder',colOrder);
	  29 grid_addBars(erd_r, 'h_scale',H.scale);
	  30 fig_set(5)
	  31 H= grid_plot(erd_lar, mnt, defopt_erps, 'colorOrder',colOrder);
 	 32 grid_addBars(erd_lar_r, 'h_scale',H.scale);
	  33 
 	 34 fig_set(2);
	  35 H= scalpEvolutionPlusChannel(erd, mnt, clab, ival_scalps, defopt_scalp_erp2, ...
 	 36                              'colorOrder',colOrder);
 	 37 grid_addBars(erd_r);
 	  38 
  	 39 fig_set(4, 'shrink',[1 2/3]);
	  40 scalpEvolutionPlusChannel(erd_r, mnt, clab, ival_scalps, defopt_scalp_r2);
	  41 
