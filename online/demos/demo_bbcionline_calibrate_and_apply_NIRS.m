BC= [];
BC.fcn= @bbci_calibrate_tinyNIRS;
BC.folder=  fullfile(BTB.DataDir, 'demoMat');
BC.file= fullfile('VPean_10_07_26', 'NIRS', 'real_movementVPean');
BC.read_fcn= @file_loadNIRSMatlab;
BC.read_param= {'Signal','oxy'};
BC.marker_fcn= @mrk_defineClasses;
BC.marker_param= {{1, 2; 'left', 'right'}};

% define a tmp folder
BC.log.folder= BTB.TmpDir;

% rewrite to bbci variable
bbci= struct('calibrate', BC);
% do the calibration
[bbci, calib]= bbci_calibrate(bbci);


%% Simulate Online processing

% load feedback file:
file= fullfile(BC.folder, 'VPean_10_07_26', 'NIRS', 'real_movementVPean');

[cnt, mrk]= file_loadNIRSMatlab(file, 'Signal','oxy');

% test consistency of classifier outputs in simulated online mode
bbci.source.acquire_fcn= @bbci_acquire_offline;
bbci.source.acquire_param= {cnt, mrk, struct('blocksize',200)};

% define some logging
bbci.log.output= 'screen&file';
bbci.log.folder= BTB.TmpDir;
bbci.log.classifier= 1;

% start the feedback
data= bbci_apply_uni(bbci);

% analyse the logged feedback
log_format= '%fs | [%f] | {cl_output=%f}';
[time, cfy, ctrl]= textread(data.log.filename, log_format, ...
                            'commentstyle','shell');

cnt_cfy= struct('fs', 1/mean(diff(time)), 'x',cfy, ...
                'clab', {{sprintf('cfy %s vs %s', calib.result.classes{:})}});
epo_cfy= proc_segmentation(cnt_cfy, calib.mrk, [-10000 20000]);
fig_set(1, 'Name','classifier output', 'Clf',1);
plot_channel(epo_cfy);

epo_auc= proc_aucValues(epo_cfy);
fig_set(2, 'Clf',1, 'Name','AUC of classifier outputs');
plot_channel(epo_auc);

% The 