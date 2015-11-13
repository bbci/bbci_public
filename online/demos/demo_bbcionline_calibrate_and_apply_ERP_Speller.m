% DEMO_BBCIONLINE_CALIBRATE_AND_APPY_ERP_SPELLER
%   This script demonstates a typical use case of the online part of
%   the BBCI Toolbox. Given calibration data, a classifier is trained on
%   that data using a calibration function. That function outputs an
%   online processing chain in the variable 'bbci'. Then one typically
%   modifies certain points of 'bbci' (e.g., depending on the used hardware
%   a specific acquire function has to be specified) and starts the fun.


BC= [];
BC.fcn= @bbci_calibrate_ERPSpeller;
BC.folder= fullfile(BTB.DataDir, 'demoRaw');
BC.file= fullfile('VPiac_10_10_13', 'calibration_CenterSpellerMVEP_VPiac');
BC.read_param= {'fs',100};
BC.marker_fcn= @mrk_defineClasses;
BC.marker_param= {{[31:49], [11:29]; 'target', 'nontarget'}};

% In demos, we just write to the temp folder. Otherwise, the default
% choice would be fine.
BC.save.folder= BTB.TmpDir;
BC.log.folder= BTB.TmpDir;

bbci= struct('calibrate', BC);

[bbci, calib]= bbci_calibrate(bbci);
%bbci_save(bbci, calib);


% test consistency of classifier outputs in simulated online mode
bbci.source.acquire_fcn= @bbci_acquire_offline;
bbci.source.acquire_param= {calib.cnt, calib.mrk};

bbci.log.output= 'screen&file';
bbci.log.folder= BTB.TmpDir;
bbci.log.classifier= 1;

data= bbci_apply_uni(bbci);

log_format= '%fs | M(%u) | %fs | [%f] | %s';
[time, marker_desc, marker_time, cfy, control]= ...
    textread(data.log.filename, log_format, ...
             'commentstyle','shell');

% markers acquired in simulated online mode are consistent
isequal(marker_desc, calib.mrk.event.desc)

ref_ival= bbci.feature.proc{1}{2};
cfy_ival= bbci.feature.proc{2}{2};
epo= proc_segmentation(calib.cnt, calib.mrk, bbci.feature.ival, ...
                       'clab', bbci.signal.clab);
fv= proc_baseline(epo, ref_ival);
fv= proc_jumpingMeans(fv, cfy_ival);
out= applyClassifier(fv, bbci.classifier.C);

% validate classifier outputs of simulated online and offline processing
max(out(:)- cfy)


% extract control signals
isctrl= cellfun(@(x)(length(x)>2), control);
control_str= sprintf('%s\n', control{find(isctrl)});
[var_name, var_value]= strread(control_str, '{%s%f}', 'delimiter','=');
var_value'
