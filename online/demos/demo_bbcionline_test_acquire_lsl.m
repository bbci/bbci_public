% DEMO_BBCIONLINE_APPLY_LSL_STREAMING
% this is just for testing / demonstrating the streaming of EEG data using
% lsl

% set up dummy classifier
C= struct('b', 0);
C.w= randn(8*2, 1);  % 2 log-bandpower feature per channel

% setup the bbci variable to define the online processing chain
bbci= struct;
bbci.source.acquire_fcn= @bbci_acquire_lsl;

% define the dummy electrode setting
clab = {'AF5' 'AF3' 'AF1' 'AFz' 'AF2' 'AF4' 'AF6' ...
        'F5' 'F3', 'F1' 'Fz' 'F2' 'F4' 'F6' ...
        'FC7' 'FC5'};

bbci.signal.clab = clab;
% provide clab and markerstreamname to lsl acquire function
bbci.source.acquire_param = {'clab', clab, 'markerstreamname', 'MyMarkerStream'};

bbci.feature.proc= {@proc_variance, @proc_logarithm};
bbci.feature.ival= [-500 0];

bbci.classifier.C= C;

% specify file locations and logging
% bbci.log.output= 'screen&file';
% bbci.log.file= fullfile(BTB.DataDir, 'tmp\log');    
bbci.source.record_signals = 0;
bbci.source.record_basename = fullfile(BTB.DataDir,'tmp\lsl_test');
bbci.quit_condition.running_time = 170;
bbci_apply(bbci);
