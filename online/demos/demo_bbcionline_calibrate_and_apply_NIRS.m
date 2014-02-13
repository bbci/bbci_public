BTB.NirsMatDir = [BTB.DataDir 'nirs/uni/'];

BC= [];
BC.fcn= @bbci_calibrate_tinyNIRS;
BC.read_fcn=@file_NIRSreadMatlab;
BC.folder= BTB.NirsMatDir;
BC.file= 'VPeag_10_06_17/ni_imag_fbarrow_pcovmeanVPeag*';
%BC.file= 'VPeae_10_03_05/ni_imag_fbarrow_pcovmeanVPeae*';
%BC.file= 'VPeah_10_06_19/ni_imag_fbarrow_pcovmeanVPeah*';
%BC.file= 'VPeaj_10_06_22/ni_imag_fbarrow_pcovmeanVPeaj*';

% define a tmp folder
BC.save.folder= BTB.TmpDir;
BC.log.folder= BTB.TmpDir;

% rewrite to bbci variable
bbci= struct('calibrate', BC);
% do the calibration
[bbci, calib]= bbci_calibrate(bbci);
% save the classifier
bbci_save(bbci, calib);


%%

% load feedback file:
file = [BTB.NirsMatDir 'VPeag_10_06_17/ni_imag_fbarrow_pmeanVPeag'];
%file = [BTB.NirsMatDir 'VPeae_10_03_05/ni_imag_fbarrow_pmeanVPeae'];
%file = [BTB.NirsMatDir 'VPeah_10_06_19/ni_imag_fbarrow_pmeanVPeah'];
%file = [BTB.NirsMatDir 'VPeaj_10_06_22/ni_imag_fbarrow_pmeanVPeaj'];

[cnt, mrk]= file_NIRSreadMatlab(file);

% test consistency of classifier outputs in simulated online mode
bbci.source.acquire_fcn= @bbci_acquire_offline;
bbci.source.acquire_param= {cnt, mrk, struct('blocksize',500)};

% define some logging
bbci.log.output= 'screen&file';
bbci.log.folder= BTB.TmpDir;
bbci.log.classifier= 1;

% start the feedback
data= bbci_apply(bbci);

% analyse the logged feedback
log_format= '%fs | [%f] | {cl_output=%f}';
[time, cfy, ctrl]= textread(data.log.filename, log_format, ...
                            'delimiter','','commentstyle','shell');

cnt_cfy= struct('fs', 2, 'x',cfy, ...
                'clab', {{sprintf('cfy %s vs %s', calib.result.classes{:})}});
epo_cfy= proc_segmentation(cnt_cfy, calib.mrk, [0 10000]);
fig_set(1, 'name','classifier output'); clf;
plot_channel(epo_cfy, 1, 'YUnit','[a.u.]');
