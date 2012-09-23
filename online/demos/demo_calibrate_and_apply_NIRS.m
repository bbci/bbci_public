BBCI.NirsMatDir = [BBCI.DataDir 'nirs/uni/'];

BC= [];
BC.fcn= @bbci_calibrate_NIRS_tiny;
BC.read_fcn=@file_NIRSreadMatlab;
BC.folder= BBCI.NirsMatDir;
BC.file= 'VPeag_10_06_17/ni_imag_fbarrow_pcovmeanVPeag*';

% define a tmp folder
BC.save.folder= BBCI.TmpDir;
BC.log.folder= BBCI.TmpDir;

% rewrite to bbci variable
bbci= struct('calibrate', BC);
% do the calibration
[bbci, calib]= bbci_calibrate(bbci);
% save the classifier
bbci_save(bbci, calib);


%%

% load feedback file:
file = [BBCI.NirsMatDir 'VPeag_10_06_17/ni_imag_fbarrow_pmeanVPeag'];
[cnt, mrk]= file_NIRSreadMatlab(file);

% test consistency of classifier outputs in simulated online mode
bbci.source.acquire_fcn= @bbci_acquire_offline;
%bbci.source.acquire_param= {calib.cnt, calib.mrk, struct('blocksize',100)};
bbci.source.acquire_param= {cnt, mrk, struct('blocksize',80)};

% define some logging
bbci.log.output= 'screen&file';
bbci.log.folder= BBCI.TmpDir;
bbci.log.classifier= 1;

% start the feedback
data= bbci_apply(bbci);

% analyse the logged feedback
log_format= '%fs | [%f] | {cl_output=%f}';
[time, cfy, ctrl]= textread(data.log.filename, log_format, ...
                            'delimiter','','commentstyle','shell');

cnt_cfy= struct('fs',25, 'x',cfy, ...
                'clab', {{sprintf('cfy %s vs %s', calib.result.classes{:})}});
epo_cfy= proc_segmentation(cnt_cfy, calib.mrk, [-20000 30000]);
fig_set(1, 'name','classifier output'); clf;
plot_channel(epo_cfy, 1, 'YUnit','[a.u.]');
