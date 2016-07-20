function [bbci, data]= bbci_calibrate_csp_tiny(bbci, data)
%BBCI_CALIBRATE_CSP_TINY - Calibrate for SMR Modulations with CSP (Tiny ver.)
%
%This function is called by bbci_calibrate 
%(if BBCI.calibate.fcn is set to @bbci_calibrate_csp_tiny).
%Via BBCI.calibrate.settings, the details can be specified, see below.
%
%Synopsis:
% [BBCI, DATA]= bbci_calibrate_csp_tiny(BBCI, DATA)
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
%  ival: [1x2 DOUBLE] interval on which CSP is performed.
%  band: [1x2 DOUBLE] frequency band on which CSP is performed.
%  clab: [CELL] Labels of the channels that are used for classification,
%     default {'not','E*','Fp*','AF*','OI*','I*','*9','*10'}.
%  nPatters: [INT>0] number of CSP patterns which are considered from each
%     side of the eigenvalue spectrum. Note, that not neccessarily all of
%     these are used for classification, see settings.pattern.
%     Default is 3.
%  model: [CHAR or CELL] Classification model.
%     Default {'RLDAshrink', 'gamma',0, store_means',1, 'scaling',1}.

% 11-2011 Benjamin Blankertz


default_clab=  {'not','E*','Fp*','AF*','OI*','I*','*9','*10'};
default_model= {@train_RLDAshrink, 'Gamma',0, 'StoreMeans',1, 'Scaling',1};

props= {'clab'         default_clab   'CELL{CHAR}'
        'ival'         [750 3750]     '!DOUBLE[1 2]'
        'band'         [8 33]         '!DOUBLE[1 2]'
        'nPatterns'    3              '!INT'
        'model'        default_model  'FUNC|CELL'
        'filtOrder'    5              '!INT'
       };
opt= opt_setDefaults('bbci.calibrate.settings', props);

[filt_b,filt_a]= butter(opt.filtOrder, opt.band/data.cnt.fs*2);
cnt_flt= proc_filt(data.cnt, filt_b, filt_a);

bbci.signal.clab= data.cnt.clab(util_chanind(data.cnt, opt.clab));

fv= proc_segmentation(cnt_flt, data.mrk, opt.ival, 'clab',bbci.signal.clab);
[fv_csp, csp_w, A, la]= proc_csp(fv, 'SelectFcn',...
                                 {@cspselect_equalPerClass, opt.nPatterns});

bbci.signal.proc= {{@online_linearDerivation, csp_w}, ...
                   {@online_filt, filt_b, filt_a}};

bbci.feature.ival= [-750 0];
bbci.feature.proc= {@proc_variance, @proc_logarithm};

fv_csp= bbci_calibrate_evalFeature(fv_csp, bbci.feature);
bbci.classifier.C= trainClassifier(fv_csp, opt.model);

bbci.quit_condition.marker= 255;
