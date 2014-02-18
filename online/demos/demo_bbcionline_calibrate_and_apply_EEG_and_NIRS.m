%% first do the calibration for the NIRS:
BC= [];
BC.fcn= @bbci_calibrate_tinyNIRS;
BC.read_fcn=@file_loadNIRSMatlab;
BC.read_param= {'Signal','oxy'};
BC.folder=  fullfile(BTB.DataDir, 'demoMat');
BC.file= fullfile('VPean_10_07_26', 'NIRS', 'real_movementVPean');
BC.marker_fcn= @mrk_defineClasses;
BC.marker_param= {{1, 2; 'left', 'right'}};
BC.save.folder= BTB.TmpDir;
BC.log.folder= BTB.TmpDir;

bbci_nirs= struct('calibrate', BC);
[bbci_nirs, calib_nirs]= bbci_calibrate(bbci_nirs);


%% now do the calibration for the EEG data:
BC= [];
BC.fcn= @bbci_calibrate_tinyCsp;
BC.folder=  fullfile(BTB.DataDir, 'demoRaw');
BC.file= fullfile('VPean_10_07_26', 'real_movementVPean');
BC.read_fcn= @file_readBV;
BC.read_param= {'fs',100};
BC.marker_fcn= @mrk_defineClasses;
BC.marker_param= {{1, 2; 'left', 'right'}};
BC.save.folder= BTB.TmpDir;
BC.log.folder= BTB.TmpDir;

bbci= struct('calibrate', BC);

[bbci, calib_eeg]= bbci_calibrate(bbci);


%% Putting things together
% for signal:
bbci.signal(1).source= 1;
bbci.signal(2).source= 2;

% for feature:
bbci.feature(2)= bbci_nirs.feature;
bbci.feature(1).signal= 1;
bbci.feature(2).signal= 2;

% for classifier:
bbci.classifier(2)= bbci_nirs.classifier;
bbci.classifier(1).feature= 1;
bbci.classifier(2).feature= 2;

% for control:
bbci.control(1).classifier= 1;
bbci.control(2).classifier= 2;

% the usual setting for log:
bbci.log.output= 'screen&file';
bbci.log.folder= BTB.TmpDir;
bbci.log.classifier= 1;

% For online simulation, we need to synchronize the two data sets
[calib_eeg.cnt, calib_eeg.mrk]= ...
    proc_selectIval(calib_eeg.cnt, calib_eeg.mrk, ...
                    [calib_eeg.mrk.time(1)-5000 inf]);
[calib_nirs.cnt, calib_nirs.mrk]= ...
    proc_selectIval(calib_nirs.cnt, calib_nirs.mrk, ...
                    [calib_nirs.mrk.time(1)-5000 inf]);

% Define acquire functions for online simulation
bbci.source(1).acquire_fcn= @bbci_acquire_offline;
bbci.source(1).acquire_param= {calib_eeg.cnt, calib_eeg.mrk};
bbci.source(2).acquire_fcn= @bbci_acquire_offline;
bbci.source(2).acquire_param= {calib_nirs.cnt, calib_nirs.mrk};
% acquiring NIRS must not block acquiring EEG
bbci.source(2).min_blocklength= 0;

%% perform the multimodal feedback
data= bbci_apply(bbci);

%% analyze the outputs
log_format= '%fs | CTRL%d | [%f] | {cl_output=%f}';
[time, cfy_no, cfy, ctrl]= textread(data.log.filename, log_format, ...
                            'delimiter','','commentstyle','shell');
idx_EEG= find(cfy_no==1);
idx_NIRS= find(cfy_no==2);

mrk_cfy= calib_eeg.mrk;
cnt_cfy_EEG= struct('fs', 1/mean(diff(time(idx_EEG))), ...
                    'x',  cfy(idx_EEG), 'clab',{{'cfy-EEG'}});
epo_cfy_EEG= proc_segmentation(cnt_cfy_EEG, mrk_cfy, [-5000 15000]);
fig_set(1, 'Name','EEG classifier output', 'clf',1);
plot_channel(epo_cfy_EEG);

cnt_cfy_NIRS= struct('fs', 1/mean(diff(time(idx_NIRS))), ...
                     'x',  cfy(idx_NIRS), 'clab',{{'cfy-NIRS'}});
epo_cfy_NIRS= proc_segmentation(cnt_cfy_NIRS, mrk_cfy, [-5000 15000]);
fig_set(2, 'Name','NIRS classifier output', 'clf',1);
plot_channel(epo_cfy_NIRS);

% Note: this is just a demo. Here, the same data was used for training
%  the classifiers and evaluation.
