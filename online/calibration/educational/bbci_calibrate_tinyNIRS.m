function [bbci,data]= bbci_calibrate_NIRS_tiny(bbci, data)
%BBCI_CALIBRATE_CSP_TINY - Calibrate NIRS data (Tiny ver.)
%
%This function is called by bbci_calibrate 
%(if BBCI.calibate.fcn is set to @bbci_calibrate_NIRS_tiny).
%Via BBCI.calibrate.settings, the details can be specified, see below.
%
%Synopsis:
% [BBCI, DATA]= bbci_calibrate_NIRS_tiny(BBCI, DATA)
% 
%Arguments:
%  BBCI -  the field 'calibrate.settings' holds parameters specific to
%          calibrate CSP-based BCI processing.
%  DATA -  holds the calibration data
%  
%Output:
%  BBCI - Updated BBCI structure in which all necessary fields for
%     online operation are set, see bbci_apply_structures.
%  DATA - As input.
%
%BBCI.calibrate.settings may include the following parameters:
%  ival - [1x2 DOUBLE] interval which is used to calculate training features,
%     (msec), default: [4000 8000]     
%  ref_ival - [1x2 DOUBLE] reference interval (msec), default [-2000 2000]
%  clab - [CELL] Labels of the channels that are used for classification,
%     default {'*'}.
%  model - [CHAR or CELL] Classification model.
%     Default {'RLDAshrink', 'gamma',0, store_means',1, 'scaling',1}.

% 09-2012 S. Fazli


default_clab=  {'*'};
default_model= {@train_RLDAshrink, 'Gamma',0, 'StoreMeans',1, 'Scaling',1};

props= {'clab'       default_clab    'CELL{CHAR}'
        'ref_ival'   [-2000 2000]    '!DOUBLE[1 2]'
        'ival'       [4000 8000]     '!DOUBLE[1 2]'
        'model'      default_model   'FUNC|CELL'
       };
opt= opt_setDefaults('bbci.calibrate.settings', props);

% make epochs:
segmentation_ival= [opt.ref_ival(1) opt.ival(2)];
fv= proc_segmentation(data.cnt, data.mrk, segmentation_ival, ...
                      'clab', opt.clab);
fv= proc_baseline(fv, opt.ref_ival);
fv= proc_jumpingMeans(fv, opt.ival);

bbci.signal.clab = data.cnt.clab;
bbci.signal.proc={};

bbci.feature.ival= [-5000 0];
bbci.feature.proc= {@proc_meanAcrossTime};

bbci.classifier.C= trainClassifier(fv, opt.model);

opt_xv= struct('SampleFcn',  {{@sample_chronKFold, 10}});
[loss,loss_std]= crossvalidation(fv, opt.model, opt_xv);
fprintf('NIRS classifier trained');
bbci_log_write(data.log.fid, 'CV loss: %2.1f +/- %2.1f%%', ...
               100*loss, 100*loss_std);

data.result.classes=fv.className;
