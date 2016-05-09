# A Gentle Introduction to the BBCI Toolbox for Offline Analysis

To follow this tutorial, you need to have the BBCI Matlab toolbox installed
[ToolboxSetup](ToolboxSetup.markdown) and know about its data structures
[ToolboxData](ToolboxData.markdown).

Here, you will explore some data structures, do some initial
analysis (e.g. plotting ERPs) manually (i.e., without using the toolbox
functions), and then you will see how it can be done with the toolbox. The manual
analysis serves the following purpose: Many of the toolbox functions are (in
principle) simple, but the code sometimes gets quite complicated, because the code
should be very general. The manual analysis demonstrates this simplicity. So
don't be afraid of the toolbox
- it's not magic!

This is a hands-on tutorial. It only makes sense, if you do it side-by-side
with a running matlab where you execute all the code.

### Table of Contents

- [cnt](#Cnt) - _Exploring the data structure `cnt` which holds continuous signals_
- [mnt](#Mnt) - _Exploring the montage structure `mnt` which defines the electrode layout for scalp plots_
- [mrk](#Mrk) - _Exploring the marker structure `mrk` which specifies timing and type of events_
- [epo](#Epo) - _Segmenting continuous signals into epochs and plotting ERPs_
- [scalp maps](#ScalpTopographies) - _Plotting scalp topographies and selecting suitable time intervals_
- [classification](#ErpClassification) - _Extracting features from ERP data and classification_


## Exploring the data structure `cnt`  <a id="Cnt"></a>

A first look at the data structure `cnt` which holds the continuous
(un-segmented) EEG signals.

```matlab
file= fullfile(BTB.DataDir, 'demoRaw', 'VPiac_10_10_13/calibration_CenterSpellerMVEP_VPiac');
[cnt, vmrk]= file_readBV(file, 'Fs',100);
% -> information in help shows how to define a filter

% data structure of continuous signals
cnt
% Fields of cnt - most important are clab (channel labels), x (data) and fs (sampling rate).    
% The data cnt.x is a two dimensional array with dimension TIME x CHANNELS.
% This is a cell array of strings that hold the channel labels. It corresponds to the second dimension of cnt.x.
cnt.clab
% Index of channel Cz
strmatch('Cz', cnt.clab)
% Index of channel P1? Why are there two?
strmatch('P1', cnt.clab)
cnt.clab([49 55])
% Ah, it matches also P10. To avoid that, use option 'exact' in strmatch
strmatch('P1', cnt.clab, 'exact')
% Now it works. The toolbox function 'chanind' does exact match by default:
util_chanind(cnt, 'P1')
% But it is also more powerful. And hopefully intuitive:
idx= util_chanind(cnt, 'P*')
cnt.clab(idx)
idx= util_chanind(cnt, 'P#')
cnt.clab(idx)
idx= util_chanind(cnt, 'P5-6')
cnt.clab(idx)
idx= util_chanind(cnt, 'P3,z,4')
cnt.clab(idx)
idx= util_chanind(cnt, 'F3,z,4', 'C#', 'P3-4')
cnt.clab(idx)
% Be aware that intervals like 'P3-4' correspond to the rows on the scalps layout, i.e.
% P3-4 -> P3, P1, Pz, P2, P4; and F7-z -> F7,F5,F3,F1,Fz
% Furthermore, # matches all channels in the respective row: but C# does not match CP2.
% (but not the temporal locations, i.e. CP# does not match TP7)
```

## The montage structure `mnt` defining electrode layout   <a id="Mnt"></a>

```matlab
% data structure defining the electrode layout
% Fields of mnt, most importantly clab, x, y which define the electrode montage.
mnt= mnt_setElectrodePositions(cnt.clab)
mnt.clab
% x-coordinates of the first 10 channels in the two projects (from above with nose pointing up).
mnt.x(1:10)
% and the corresponding y coordinates.
mnt.y(1:10)
clf
text(mnt.x, mnt.y, mnt.clab); 
% displays the electrode layout. 'axis equal' may required to show it in the right proportion.
% The function scalpPlot can be used to display distributions (e.g. of voltage) on the scalp:
axis([-1 1 -1 1])
plot_scalp(mnt, cnt.x(200,:));
% The function plot_scalp is kind of a low level function. There is no
% mechanisms that can guarrantee the correct association of the channels
% from the map with the channels in the electrode montage. The user has
% to take care of this (or use another function).
% The following lines demonstrate the issue:
plot_scalp(mnt, cnt.x(200,1:63))
% -> throws an error
% If you use a subset of channels, specify channel labels in 'WClab':
plot_scalp(mnt, cnt.x(200,1:63), 'WClab',cnt.clab(1:63))
plot_scalp(mnt, cnt.x(200,[1:30 35:64]), 'WClab',cnt.clab([1:30 35:64]))
% This results in a wrong mapping:
plot_scalp(mnt, cnt.x(200,[1:30 35:64]), 'WClab',cnt.clab([1:60]))
```

## The Marker structure `mrk`   <a id="Mrk"></a>
To make sense of the data, we need to know what happened when. This is stored in the marker data structure `mrk`. Markers (triggers) are stored into the EEG signals by the program that controls the stimulus presentation (or BCI feedback). Furthermore, markers can be triggered by a response of the participant (like button presses), or by other sensors (visual sensors that register the flashing of an object on a display).

```matlab
% data structure defining the markers (trigger events in the signals)
vmrk
vmrk.event.desc(1:100)
classDef= {31:46, 11:26; 'target', 'nontarget'};
mrk= mrk_defineClasses(vmrk, classDef);
mrk.y(:,1:40)
% row 1 of mrk.y defines membership to class 1, and row 2 to class 2
mrk.event.desc(1:40)
sum(mrk.y,2)
it= find(mrk.y(1,:));
it(1:10)
% are the indices of target events
```

## Segmentation and plotting of ERPs   <a id="Epo"></a>
Having the basic ingredients together, we can start a simple ERP analsis

```matlab
% segmentation of continuous data in 'epochs' based on markers
epo= proc_segmentation(cnt, mrk, [-200 800])
epo
iCz= util_chanind(epo, 'Cz') % find the index of channel Cz
plot(epo.t, epo.x(:,iCz,1))
xlabel('time  [ms]');
ylabel('potential @Cz  [\muV]');
plot(epo.t, epo.x(:,iCz,2))
plot(epo.t, epo.x(:,iCz,it(1))) %Plot the EEG trace of an evoked potential
plot(epo.t, epo.x(:,iCz,it(2)))
% The ERP of the target trials is obtained by averaging across all target trials:
plot(epo.t, mean(epo.x(:,iCz,it),3)) %Plot the ERP of channel Cz
in= find(mrk.y(2,:));
hold on
plot(epo.t, mean(epo.x(:,iCz,in),3), 'k')
% you should put labels to the axes, but ...

% visualization of ERPs with toolbox functions
plot_channel(epo, 'Cz')
grid_plot(epo);
grd= sprintf('F3,Fz,F4\nC3,Cz,C4\nP3,Pz,P4')
mnt= mnt_setGrid(mnt, grd);
grid_plot(epo, mnt, defopt_erps);
grd= sprintf(['scale,_,F5,F3,Fz,F4,F6,_,legend\n' ...
              'FT7,FC5,FC3,FC1,FCz,FC2,FC4,FC6,FT8\n' ...
              'T7,C5,C3,C1,Cz,C2,C4,C6,T8\n' ...
              'P7,P5,P3,P1,Pz,P2,P4,P6,P8\n' ...
              'PO9,PO7,PO3,O1,Oz,O2,PO4,PO8,PO10']);
mnt= mnt_setGrid(mnt, grd);
% One can also use template grids with
mnt= mnt_setGrid(mnt, 'M');
%
grid_plot(epo, mnt, defopt_erps);
% baseline drifts:
clf; plot(cnt.x(1:1000,32))
% To get rid of those, do a baseline correction
epo= proc_baseline(epo, [-200 0]);
H= grid_plot(epo, mnt, defopt_erps);
epo_auc= proc_aucValues(epo);
grid_addBars(epo_auc, 'HScale',H.scale);
```

## Plotting scalp topographies   <a id="ScalpTopographies"></a>

```matlab
% visualization of scalp topograhies
plot_scalpEvolutionPlusChannel(epo, mnt, {'Cz','PO7'}, [200:50:500], defopt_scalp_erp);
figure(2);
plot_scalpEvolutionPlusChannel(epo_auc, mnt, {'Cz','PO7'}, [200:50:500], defopt_scalp_r);
% refine intervals
ival= [250 300; 350 400; 420 450; 490 530; 700 740];
plot_scalpEvolutionPlusChannel(epo_auc, mnt, {'Cz','PO7'}, ival, defopt_scalp_r);
figure(1);
plot_scalpEvolutionPlusChannel(epo, mnt, {'Cz','PO7'}, ival, defopt_scalp_erp);

plot_scoreMatrix(epo_auc, ival)
ival= procutil_selectTimeIntervals(epo_auc, 'visualize', 1, 'visu_scalps', 1)

%% see part 2 below
```

## Classification of ERP data   <a id="ErpClassification"></a>

```matlab
% -- classification on spatial features
ival= [0 1000];
epo= proc_segmentation(cnt, mrk, [-200 1000]);
epo= proc_baseline(epo, [-200 0]);
fv= proc_selectIval(epo, ival);
ff= fv;
clear loss
for ii= 1:size(fv.x,1),
  ff.x= fv.x(ii,:,:);
  loss(ii)= crossvalidation(ff, @train_RLDAshrink, 'sampleFcn', {@sample_KFold, 5}, 'LossFcn',@loss_rocArea);
end

clf;
acc= 100-100*loss;
plot(fv.t, acc);


% -- classification on temporal features
fv= proc_selectIval(epo, [0 800]);
ff= fv;
clear loss
for ii= 1:size(fv.x,2),
  ff.x= fv.x(:,ii,:);
  loss(ii)= crossvalidation(ff, @train_RLDAshrink, 'sampleFcn', {@sample_KFold, 5}, 'LossFcn',@loss_rocArea);
end
acc= 100-100*loss;
plot_scalp(mnt, acc, 'CLim','range', 'Colormap', cmap_whitered(31));



% -- classification on spatio-temporal features
ival= [150:50:700; 200:50:750]';
fv= proc_jumpingMeans(epo, ival);
loss_spatioTemp = crossvalidation(fv, @train_RLDAshrink, 'sampleFcn', {@sample_KFold, 5}, 'LossFcn',@loss_rocArea);

%with interval selection based on heuristics
%epo_auc= proc_aucValues(epo);
%ival= select_time_intervals(epo_auc, 'visualize', 1, 'visu_scalps', 1, ...
%                            'nIvals',5);
%fv= proc_jumpingMeans(epo, ival);
%loss_spatioTemp = crossvalidation(fv, @train_RLDAshrink, 'sampleFcn', {@sample_KFold, 5}, 'LossFcn',@loss_rocArea);

% For faster performance, you can switch off type-checking and the 
% history for validation.
tcstate= bbci_typechecking('off');
BTB.History= 0;
% xvalidation(...)
% Put typechecking back in the original state:
bbci_typechecking(tcstate);
```


## Part 2:

```matlab
file= 'demoRaw/VPiac_10_10_13/calibration_CenterSpellerMVEP_VPiac';

% read header to determine sampling frequency
hdr= file_readBVheader(file);
% define low-pass filter
Wps= [40 49]/hdr.fs*2;
[n, Ws]= cheb2ord(Wps(1), Wps(2), 3, 50);
[filt.b, filt.a]= cheby2(n, 50, Ws);

% the following applies the low-pass filter to the data in original sampling
% frequency, and then subsamples signals at 100 Hz
[cnt, vmrk]= file_readBV(file, 'Fs',100, 'Filt',filt);

% Re-referencing to linked-mastoids 
A= eye(length(cnt.clab));
iA1= util_chanind(cnt.clab,'A1');
A(iA1,:)= -0.5;
A(:,iA1)= [];
cnt= proc_linearDerivation(cnt, A);

% high-pass filtering to reduce drifts
b= procutil_firlsFilter(0.5, cnt.fs);
cnt= proc_filtfilt(cnt, b);

% define marker structure mrk as last time
classDef= {31:46, 11:26; 'target', 'nontarget'};
mrk= mrk_defineClasses(vmrk, classDef);
% data structure defining the electrode layout
mnt= mnt_setElectrodePositions(cnt.clab)
grd= sprintf(['scale,_,F5,F3,Fz,F4,F6,_,legend\n' ...
              'FT7,FC5,FC3,FC1,FCz,FC2,FC4,FC6,FT8\n' ...
              'T7,C5,C3,C1,Cz,C2,C4,C6,T8\n' ...
              'P7,P5,P3,P1,Pz,P2,P4,P6,P8\n' ...
              'PO9,PO7,PO3,O1,Oz,O2,PO4,PO8,PO10']);
mnt= mnt_setGrid(mnt, grd);

% Artifact rejection based on variance criterion
mrk= reject_varEventsAndChannels(cnt, mrk, [-200 800], 'visualize',1, 'verbose', 1);

% Segmentation as before, but with high-passed cnt and cleaned mrk
epo= proc_segmentation(cnt, mrk, [-200 800]);
% when using a high-pass filter, subtracting baseline could be omitted
epo= proc_baseline(epo, [-200 0]);
  
% Artifact rejection based on maxmin difference criterion on frontal chans
crit_maxmin= 60;
[epo_clean, iArte]= proc_rejectArtifactsMaxMin(epo, crit_maxmin, ...
                     'clab',{'F9,z,10','AF3,4'}, 'ival',[0 800], 'verbose',1);

epo_arte=  proc_selectEpochs(epo, iArte);
epo= epo_clean;

figure(2)
% ERPs of artifacts only (many artifacts average out)
grid_plot(epo_arte, mnt, defopt_erps);

figure(1)
% ERPs of cleaned data
H= grid_plot(epo, mnt, defopt_erps);
epo_auc= proc_aucValues(epo);
grid_addBars(epo_auc, 'HScale',H.scale);

figure(2)
ival= procutil_selectTimeIntervals(epo_auc, 'Visualize',1, 'VisuScalps',1);

figure(1)
epo_r= proc_rSquareSigned(epo);
ival= procutil_selectTimeIntervals(epo_r, 'Visualize',1, ...
                                   'VisuScalps',1, 'Mnt',mnt);

% in order to extract only certain ERP component, constraints can be defined
constraint= ...
    {{-1, [150 300], {'I#','O#','PO7,8','P9,10'}, [50 300]}, ...
     {1, [200 350], {'FC3-4','C3-4'}, [200 400]}, ...
     {1, [400 500], {'CP3-4','P3-4'}, [350 600]}};
ival= procutil_selectTimeIntervals(epo_auc, 'Visualize',1, 'VisuScalps',1, ...
                    'Mnt',mnt, 'Constraint', constraint, 'NIvals',3);
```


## Special Topic: Continuous application of classifier based on spatial feature

Probably this can be deleted - or put to another place, because this part discusses a quite specific specfic and more advanced type of analysis.
 
```matlab
%% -- Continuous application of classifier based on spatial feature
ival= [380 440];
fv= proc_jumpingMeans(epo, ival);
xvalidation(fv, 'RLDAshrink', 'LossFcn',@loss_rocArea);

C= trainClassifier(fv, @train_RLDAshrink);

cnt_cfy= proc_linearDerivation(cnt, C.w);
cnt_cfy.x= cnt_cfy.x + C.b;

epo_cfy= proc_segmentation(cnt_cfy, mrk, [-200 800]);
plot_channel(epo_cfy);

figure(2)
auc_cfy= proc_aucValues(epo_cfy);
plot_channel(auc_cfy);


%% -- Continuous application of classifier based on spatio-temporal feature
epo_ival= [-200 800];
epo= proc_segmentation(cnt, mrk, epo_ival);
epo= proc_baseline(epo, [epo_ival(1) 0]);
cfy_ival= [260 290; 320 350; 360 450; 460 530; 550 600; 690 730];
fv= proc_jumpingMeans(epo, ival);
xvalidation(fv, 'RLDAshrink', 'LossFcn',@loss_rocArea);

C= trainClassifier(fv, @train_RLDAshrink);

cnt_cfy.x= zeros(cnt.T, 1);
for tim= -epo_ival(1):1000/cnt.fs:(cnt.T/cnt.fs*1000)-epo_ival(2),
  mk= struct('time',tim, 'y',1);
  ep= proc_segmentation(cnt, mk, epo_ival);
  ep= proc_baseline(ep, [epo_ival(1) 0]);
  fv= proc_jumpingMeans(ep, cfy_ival);
  k= round((mk.time+max(ival(:)))/1000*cnt.fs)
  cnt_cfy.x(k)= C.w'*fv.x(:) + C.b;
end

epo_cfy= proc_segmentation(cnt_cfy, mrk, [-200 800]);
plot_channel(epo_cfy);

auc_cfy= proc_aucValues(epo_cfy);
plot_channel(auc_cfy);

% Validation !!
N= length(mrk.time);
idxTr= 1:N/2;
idxTe= setdiff(1:N, idxTr);
C= trainClassifier(fv, 'RLDAshrink', idxTr);


%% -- offline simulation with online module
bbci= struct;
bbci.source.acquire_fcn= @bbci_acquire_offline;
bbci.source.acquire_param= {cnt, mrk, 'blocksize',10};
bbci.source.min_blocklength= 10;

shift= max(cfy_ival(:));
bbci.feature.proc= {{@proc_baseline, [epo_ival(1) 0]-shift}, ...
                    {@proc_jumpingMeans, cfy_ival-shift}};
bbci.feature.ival= [epo_ival(1) cfy_ival(end)] - shift;

bbci.classifier.C= C;

bbci.log.output= 'screen&file';
bbci.log.file= '/tmp/cfy_log.txt';
bbci.log.classifier= 1;

data= bbci_apply(bbci);

% classifier output from logfile
log_format= '%fs | [%f] | %s';
[time, cfy, control]= ...
    textread(data.log.filename, log_format, ...
             'delimiter','','commentstyle','shell');

cnt_cfy= struct('fs',100, 'x',cfy, 'clab',{{'cfy'}});
epo_cfy= proc_segmentation(cnt_cfy, mrk, epo_ival);
plot_channel(epo_cfy);

auc_cfy= proc_aucValues(epo_cfy);
plot_channel(auc_cfy);
```
