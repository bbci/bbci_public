if exist('BTB','var') == 0
    init_bbci;
end

eeg_file= fullfile(BTB.DataDir, 'Mat', 'OV/mvep/Okba/27_10_2016', ...
                   'erp_350_350');

% Load data
try
  [cnt, mrk, mnt] = file_loadMatlab(eeg_file);
catch
  error('You need to run ''demo_convert_ERPSpeller'' first');
end
%%
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

%% mnt data structure defining the electrode layout

% Fields of mnt, most importantly clab, x, y which define the electrode montage.
mnt= mnt_setElectrodePositions(cnt.clab)
mnt.clab

% x-coordinates of the first 10 channels in the two projects (from above with nose pointing up).
mnt.x(1:8)

% and the corresponding y coordinates.
mnt.y(1:8)

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
plot_scalp(mnt, cnt.x(200,1:6), 'WClab',cnt.clab(1:6))
plot_scalp(mnt, cnt.x(200,[1:3 5:6]), 'WClab',cnt.clab([1:3 5:6]))

% This results in a wrong mapping:
plot_scalp(mnt, cnt.x(200,[1:30 35:64]), 'WClab',cnt.clab([1:60]))

%% The Marker structure mrk
% data structure defining the markers (trigger events in the signals)
mrk
mrk.event.desc(1:100)
classDef= {31:36, 11:16; 'target', 'nontarget'};
mrk= mrk_defineClasses(vmrk, classDef);
mrk.y(:,1:40)

% row 1 of mrk.y defines membership to class 1, and row 2 to class 2
mrk.event.desc(1:40)
sum(mrk.y,2)
it= find(mrk.y(1,:));
it(1:10)
% are the indices of target events
%% Segmentation and plotting of ERPs

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
plot_channel(epo, 'Cz') %plot epoched data in the channel 'Cz' target/non target
grid_plot(epo); %plot grid of channels target/nontarget
grd= sprintf('F3,Fz,F4\nC3,Cz,C4\nP3,Pz,P4')
mnt= mnt_setGrid(mnt, grd);
grid_plot(epo, mnt, defopt_erps); %grid plot with default options and a subset of channels (grd)
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
H= grid_plot(epo, mnt, defopt_erps);%grid_plot after baseline correction
epo_auc= proc_aucValues(epo);% adding score
grid_addBars(epo_auc, 'HScale',H.scale);%add bars of scores