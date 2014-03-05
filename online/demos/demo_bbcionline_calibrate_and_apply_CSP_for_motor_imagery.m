% DEMO_BBCIONLINE_CALIBRATE_AND_APPY_CSP_FOR_MOTOR_IMAGERY
%   This script demonstates a typical use case of the online part of
%   the BBCI Toolbox. Given calibration data, a classifier is trained on
%   that data using a calibration function. That function outputs an
%   online processing chain in the variable 'bbci'. Then one typically
%   modifies certain points of 'bbci' (e.g., depending on the used hardware
%   a specific acquire function has to be specified) and starts the fun.


BC= [];
BC.fcn= @bbci_calibrate_csp;
BC.folder= fullfile(BTB.DataDir, 'demoRaw');
BC.file= fullfile('VPkg_08_08_07', ...
                  'calibration_motorimageryVPkg');
BC.marker_fcn= @mrk_defineClasses;
BC.marker_param= {{1, 2, 3; 'left', 'right', 'foot'}};
%BC.fcn= @bbci_calibrate_tinyCsp;
%BC.marker_param= {{1, 2; 'left', 'right'}};

% We just log to the screen
BC.log.output= 'screen';

bbci= struct('calibrate', BC);

[bbci, calib]= bbci_calibrate(bbci);
%bbci_save(bbci, calib);


% test consistency of classifier outputs in simulated online mode
% you could also load a different data set
%   (like VPkg_08_08_07/feedback_motorimageryVPkg)
% and use that for testing
bbci.source.acquire_fcn= @bbci_acquire_offline;
bbci.source.acquire_param= {calib.cnt, calib.mrk};

% Write log to a tmp folder
bbci.log.output= 'screen&file';
bbci.log.folder= BTB.TmpDir;

data= bbci_apply(bbci);

log_format= '%fs | {cl_output=%f}';
[time, cfy]= textread(data.log.filename, log_format, ...
                      'commentstyle','shell');

cnt_cfy= struct('fs',1/mean(diff(time)), 'x',cfy, ...
                'clab', {{sprintf('cfy %s vs %s', calib.result.classes{:})}});
epo_cfy= proc_segmentation(cnt_cfy, calib.mrk, [0 5000]);
fig_set(1, 'Name','classifier output', 'Clf',1);
plot_channel(epo_cfy);
