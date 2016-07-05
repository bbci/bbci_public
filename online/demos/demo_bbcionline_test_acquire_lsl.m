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
% DEMO_BBCIONLINE_APPLY_SMR_LAP_C34_BP2_ADAPTATION_PMEAN
%  This script demonstrates how setup an online processing for
%  SMR modulations.
%  In the typical use case, these things are done by a calibrate
%  function (bbci_calibrate). But for educations reasons it is good to
%  know how these things work.


% load calibration data
% file= fullfile(BTB.DataDir, 'demoMat', 'VPkg_08_08_07', ...
%                'calibration_motorimageryVPkg');
% [cnt, mrk]= file_loadMatlab(file, 'vars',{'cnt','mrk'});

% this is just stuff to get some variables that are used below to
% define the online processing chain.
% clab= procutil_getClabForLaplacian(cnt, 'C3,4');
% tmp= proc_selectChannels(cnt, clab);
% [tmp, A]= proc_laplacian(tmp, 'clab','C3,4');
% [filt_b, filt_a]= butters(5, [9 13; 18 26]/cnt.fs*2);
C= struct('b', 0);
C.w= randn(16*2, 1);  % 2 log-bandpower feature per channel

% setup the bbci variable to define the online processing chain
bbci= struct;
bbci.source.acquire_fcn= @bbci_acquire_lsl;

 clab = {'AF5' 'AF3' 'AF1' 'AFz' 'AF2' 'AF4' 'AF6' ...
        'F5' 'F3', 'F1' 'Fz' 'F2' 'F4' 'F6' ...
        'FC7' 'FC5', 'AF5' 'AF3' 'AF1' 'AFz' 'AF2' 'AF4' 'AF6' ...
        'F5' 'F3', 'F1' 'Fz' 'F2' 'F4' 'F6' ...
        'FC7' 'FC5'};

bbci.signal.clab = clab;
% provide clab and markerstreamname to lsl acquire function
bbci.source.acquire_param = {'clab', clab};
% bbci.signal.proc= {{@online_linearDerivation, A},
%                    {@online_filterbank, filt_b, filt_a}};

bbci.feature.proc= {@proc_variance, @proc_logarithm};
bbci.feature.ival= [-500 0];

bbci.classifier.C= C;

% bbci.log.output= 'screen&file';
% bbci.log.file= fullfile(BTB.DataDir, 'tmp\log');    
bbci.source.record_signals = 1;
bbci.source.record_basename = fullfile(BTB.DataDir,'tmp\lsl_test');
bbci.quit_condition.running_time = 70;
bbci_apply(bbci);