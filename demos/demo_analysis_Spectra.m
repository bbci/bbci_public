file= 'Pavel_01_11_23/selfpaced2sPavel';

%% Load data
hdr= file_readBVheader(file);
Wps= [42 49]/hdr.fs*2;
[n, Ws]= cheb2ord(Wps(1), Wps(2), 3, 40);
[filt.b, filt.a]= cheby2(n, 50, Ws);
[cnt, mrk_orig]= file_readBV([file '*'], 'Fs',100, 'Filt',filt);

%% Marker struct
stimDef= {[65 70], [74 192];
          'left','right'};
mrk= mrk_defineClasses(mrk_orig, stimDef);

%% Electrode Montage
grd= sprintf(['EOGh,_,F3,Fz,F4,_,EOGv\n' ...
              'FC5,FC3,FC1,FCz,FC2,FC4,FC6\n' ...
              'C5,C3,C1,Cz,C2,C4,C6\n' ...
              'CP5,CP3,CP1,CPz,CP2,CP4,CP6\n' ...
              'EMGl,scale,O1,_,O2,legend,EMGr']);
mnt= get_electrodePositions(cnt.clab);
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
H= grid_plot(spec, mnt, opt_grid_spec);
%grid_markIval(band_erd);     % to shade a certain frequency band
grid_addBars(spec_r, 'HScale',H.scale);

fig_set(5);
H= grid_plot(spec_lar, mnt, opt_grid_spec);
grid_addBars(spec_lar_r, 'HScale',H.scale);

fig_set(2);
H= plot_scalpEvolutionPlusChannel(spec, mnt, clab, band_list, ...
                             defopt_scalp_power, ...
                             'ColorOrder',colOrder, ...
                             'ScalePos','horiz', ...
                             'GlobalCLim',0);
grid_addBars(spec_r);

fig_set(4, 'shrink',[1 2/3]);
plot_scalpEvolutionPlusChannel(spec_r, mnt, clab, band_list, defopt_scalp_r);


%% Do the same with subtracting the spectrum in a reference time interval
% Here we use a post-movement interval.
ref_ival= [200 1200];

mrk_ref= mrk;
mrk_ref.y= ones(1, length(mrk_ref.pos));
mrk_ref.className= {'ref'};
mrk_ref= reject_varEventsAndChannels(cnt, mrk_ref, ref_ival);
spec_baseline= proc_segmentation(cnt, mrk_ref, ref_ival);
spec_baseline= proc_spectrum(spec_baseline, [5 40], kaiser(winlen,2));
spec_baseline= proc_average(spec_baseline);
spec_ref= proc_subtractReferenceClass(spec, spec_baseline);

fig_set(6);
H= plot_scalpEvolutionPlusChannel(spec_ref, mnt, clab, band_list, ...
                             defopt_scalp_power, ...
                             'Extrapolate', 0, ...
                             'ColorOrder',colOrder);
grid_addBars(spec_r);
