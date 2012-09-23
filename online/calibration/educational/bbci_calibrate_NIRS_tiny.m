function [bbci,data]= bbci_calibrate_NIRS_tiny(bbci,data)
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
%  ival: [1x2 DOUBLE] interval which is selected for classifier estimation
%  clab: [CELL] Labels of the channels that are used for classification,
%     default {'*'}.
%  model: [CHAR or CELL] Classification model.
%     Default {'RLDAshrink', 'gamma',0, store_means',1, 'scaling',1}.

% 09-2012 S. Fazli


default_clab=  {'*'};
default_model= {@train_RLDAshrink, 'Gamma',0, 'StoreMeans',1, 'Scaling',1};

props= {'clab'         default_clab   'CELL{CHAR}'
        'segmentation_ival'     [-2000 10000] '!DOUBLE[1 2]'
        'model_ival'         [4000 8000]    '!DOUBLE[1 2]'
        'model'        default_model  'FUNC|CELL'
       };
opt= opt_setDefaults('bbci.calibrate.settings', props);

% make epochs:
fv= proc_segmentation(data.cnt,data.mrk,opt.segmentation_ival, 'clab', opt.clab);
fv= proc_baseline(fv,[-2000 2000]);
fv= proc_selectIval(fv,opt.model_ival);
fv= proc_meanAcrossTime(fv);

bbci.signal.proc={};
bbci.signal.clab = data.cnt.clab;

bbci.feature.ival =[-2000 0];
bbci.feature.proc = {@proc_meanAcrossTime};

bbci.classifier.C=trainClassifier(fv,opt.model);



[loss,loss_std]=xvalidation(fv,opt.model,'progress_bar',0,'verbosity',0);
disp(sprintf('NIRS classifier trained'))
disp(sprintf('xvalidation yields a loss of %2.1f +/- %2.1f %%',100*loss,100*loss_std))

data.result.classes=fv.className;




