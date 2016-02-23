% DEMO_BBCIONLINE_APPLY_ERP_SPELLER
%  This script demonstrates how to perform simulated online processing
%  for an ERP speller. To that end, a realistic feature extraction is
%  set up. Note, that in the normal use case this is done
%  automatically during the calibration. The calibration of the ERP Speller
%  is shown in 'demo_bbcionline_calibrate_and_apply_ERP_Speller'.
%  Here, we just define a random classifier. This classifier is apply in
%  simulated online mode, and the results of classification are read from
%  the log file. These are compared with a standard offline classification
%  analysis from the data itself (i.e., without simulating online operation).
%
%  You need to run demo_convert_ERPSpeller first (one time only).

BTB_memo= BTB;
BTB.MatDir= fullfile(BTB.DataDir, 'demoMat');

eeg_file= fullfile('VPiac_10_10_13', ...
                   'calibration_CenterSpellerMVEP_VPiac');
[cnt, mrk]= file_loadMatlab(eeg_file, 'vars',{'cnt','mrk'});

clab= {'F3','Fz','F4', 'C3','Cz','C4', 'P3','Pz','P4'};
ref_ival= [-200 0];
cfy_ival= [90 110; 110 150; 150 250; 250 400; 400 750];
% Generate random classifier of correct format
C= struct('b',0);
C.w= randn(length(clab)*size(cfy_ival,1), 1);

bbci= struct;
bbci.source.acquire_fcn= @bbci_acquire_offline;
bbci.source.acquire_param= {cnt, mrk};

bbci.signal.clab= clab;

bbci.feature.proc= {{@proc_baseline, ref_ival}, ...
                    {@proc_jumpingMeans, cfy_ival}};
bbci.feature.ival= [ref_ival(1) cfy_ival(end)];

bbci.classifier.C= C;

bbci.control.fcn= @bbci_control_ERPSpeller;
bbci.control.param= {struct('nClasses', 6, ...
                            'nSequences', 10, ...
                            'mrk2feedback_fcn', @(x)(1+mod(x-11,10)))};
bbci.control.condition.marker= [11:16, 21:26, 31:36, 41:46];

bbci.quit_condition.marker= 255;
bbci.quit_condition.running_time= 2*60;

bbci.log.output= 'screen&file';
bbci.log.file= fullfile(BTB.TmpDir, 'log');
bbci.log.classifier= 1;

data= bbci_apply_uni(bbci);
% Of course, bbci_apply would do the very same.


%% validate simulated online results with offline classification
% read markers and classifier output from logfile
log_format= '%fs | M(%u) | %fs | [%f] | %s';
[time, marker_desc, marker_time, cfy, control]= ...
    textread(data.log.filename, log_format, ...
             'commentstyle','shell');

% validate makers that evoked calculation of control signals
isequal(marker_desc, mrk.event.desc(1:length(marker_desc)))

% offline processing of the data
epo= proc_segmentation(cnt, mrk, [ref_ival(1) cfy_ival(end)], 'clab', bbci.signal.clab);
fv= proc_baseline(epo, ref_ival);
fv= proc_jumpingMeans(fv, cfy_ival);
out= applyClassifier(fv, bbci.classifier.C);

% validate classifier outputs of simulated online and offline processing
max(abs( out(1:length(cfy))' - cfy))

% extract control signals
isctrl= cellfun(@(x)(length(x)>2), control);
control_str= sprintf('%s\n', control{find(isctrl)});
[var_name, var_value]= strread(control_str, '{%s%f}', 'delimiter','=');
var_value'

BTB= BTB_memo;
