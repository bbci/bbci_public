% BBCI DEMO - Testing Matlab feedback using random signals.
%
%  The demo shows, how a Matlab-based feedback can be tested in simulated
%  online mode. As a source of signals, a random signal generator is used
%  (acquire fcn 'bbci_acquire_randomSignals').
%  For this demo, the data processing does not matter. Here, we define
%  a very simple processing chain with a random clasifiers.


clab= {'C3','Cz','C4', 'CP3','CPz','CP4'};
C= struct('b', 0);
C.w= randn(length(clab), 1);

bbci= struct;
bbci.source.acquire_fcn= @bbci_acquire_randomSignals;
bbci.source.acquire_param= {'clab',clab, 'realtime', 2};
bbci.feature.proc= {@proc_variance, @proc_logarithm};
bbci.feature.ival= [-500 0];
bbci.classifier.C= C;
bbci.quit_condition.marker= 255;

bbci.feedback.receiver= 'matlab';
bbci.feedback.fcn= @bbci_feedback_cursor;
bbci.feedback.opt= ...
    struct('trigger_classes_list', {{'left','right'}}, ...
           'countdown', 3000, ...
           'trials_per_run', 6);
bbci.feedback.log.output= 'file';
bbci.feedback.log.folder= BTB.TmpDir;

% ?how is this supposed to stop?
data= bbci_apply_uni(bbci);

pause(1); close;
fprintf('Now doing a replay of that feedback from the logfile.\n'); pause(2);

bbci_fbutil_replay(data.feedback.log.filename);

% Replay in fast forward:
%bbci_fbutil_replay(data.feedback.log.filename, 'realtime',0);
