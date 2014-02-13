%% first do the calibration for the NIRS:
BC= [];
BC.fcn= @bbci_calibrate_tinyNIRS;
BC.read_fcn=@file_NIRSreadMatlab;
BC.folder=  [BTB.DataDir 'bbciDemo/'];
BC.file= 'VPeag_10_06_17/ni_imag_fbarrow_pcovmeanVPeag*';
BC.save.folder= BTB.TmpDir;
BC.log.folder= BTB.TmpDir;

bbci_nirs= struct('calibrate', BC);
[bbci_nirs, calib_nirs]= bbci_calibrate(bbci_nirs);

bbci_nirs.source.acquire_fcn= @bbci_acquire_offline;
bbci_nirs.source.acquire_param= {calib_nirs.cnt, calib_nirs.mrk, struct('realtime',0.1,'blocksize',500)};


%% now do the calibration for the EEG data:
BC= [];
BC.fcn= @bbci_calibrate_tinyCsp;
BC.folder= BTB.RawDir;
BC.file= 'VPeag_10_06_17/imag_fbarrow_pcovmeanVPeag*';
BC.read_fcn=@file_readBV;
BC.read_param= {'fs',100};
BC.marker_fcn= @mrk_defineClasses;
BC.marker_param= {{1, 2; 'left', 'right'}};
BC.save.folder= BTB.TmpDir;
BC.log.folder= BTB.TmpDir;

bbci= struct('calibrate', BC);

[bbci, calib_eeg]= bbci_calibrate(bbci);

bbci.source(1).acquire_fcn= @bbci_acquire_offline;
bbci.source(1).acquire_param= {calib_eeg.cnt, calib_eeg.mrk, ...
                    struct('realtime',0.1)};


%%
% add the NIRS struct to bbci:

% for source:
bbci.source(2).acquire_fcn= bbci_nirs.source.acquire_fcn;
bbci.source(2).acquire_param= bbci_nirs.source.acquire_param;
  
% for signal:
bbci.signal(1).source=1;
bbci.signal(2).clab={'*'};
bbci.signal(2).proc={};
bbci.signal(2).source=2;

% for feature:
bbci.feature(1).signal=1;
bbci_nirs.feature.signal=2;
bbci.feature(2)=bbci_nirs.feature;

% for classifier:
bbci.classifier(1).feature=1;
bbci_nirs.classifier.feature=2;
bbci.classifier(2)=bbci_nirs.classifier;

% for control:
bbci.control(1).classifier=1;
bbci.control(1).fcn='';
bbci.control(1).param={};
bbci.control(1).condition=[];
bbci.control(1).source_list=1;

bbci.control(2).classifier=2;
bbci.control(2).fcn='';
bbci.control(2).param={};
bbci.control(2).condition=[];
bbci.control(2).source_list=2;

% for log:
bbci.log.output= 'screen&file';
bbci.log.folder= BTB.TmpDir;
bbci.log.classifier= 1;

% % or just load the predefined classifier
%bbci=load('/home/data/tmp/bbci_classifier_csp.mat');
bbci.source(2).min_blocklength=0;

%% perform the multimodal feedback
data= bbci_apply(bbci);

%% analyse the outputs
log_format= '%fs | %5s | [%f] | {cl_output=%f}';
[time, classi, cfy, ctrl]= textread(data.log.filename, log_format, ...
                            'delimiter','\n','commentstyle','shell');

cnt_cfy= struct('fs',2, 'x',cfy, 'clab',{{'cfy'}});
mrk_cfy= mrk_selectClasses(calib.mrk, calib.result.classes);
mrk_cfy= mrk_resample(mrk_cfy, cnt_cfy.fs);
epo_cfy= cntToEpo(cnt_cfy, mrk_cfy, [0 5000]);
fig_set(1, 'name','classifier output'); clf;
plotChannel(epo_cfy, 1);
