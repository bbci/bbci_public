function [bbci, data]= bbci_calibrate_ERP_Speller_with_ErrP_tiny(bbci, data)
%BBCI_CALIBRATE_ERP_WITH_ERRP_SPELLER_TINY - Calibrate for ERP Spellers with 
% error detection - Short version
%
%This version is for educational purpose. It shows what is absolutely
%essential for setting up a BBCI classifier for ERP Speller classification.
%
%Synopsis:
% [BBCI, DATA]= bbci_calibate_ERP_Speller_with_ErrP_tiny(BBCI, DATA)
% 
%Arguments:
%  BBCI -  the field 'calibrate' holds parameters specific to ERP Spellers.
%  DATA -  holds the calibration data
%  
%Output:
%  BBCI - Updated BBCI structure in which all necessary fields for
%     online operation are set, see bbci_apply_structures.
%  DATA - As input but added some information of the analysis that might
%     be reused in a second run

% 11-2011 Benjamin Blankertz


props= {'ref_ival'      [-200 0]             '!DOUBLE[1 2]'
        'cfy_ival'      [100 150; 150 200; 
                         200 250; 250 300;
                         300 400; 400 500;
                         500 600; 600 700]   '!DOUBLE[- 2]'
        'errp_cfy_ival' [100 200; 200 300]   '!DOUBLE[- 2]'
        'cfy_clab'      {'not','E*','Fp*','AF*','A*'}   'CHAR|CELL{CHAR}'
        'model'         @train_RLDAshrink               'FUNC|CELL'
        'nSequences'    5                               '!INT'
        'nClasses'      6                               '!INT'
        'cue_markers', [11:16,21:26,31:36,41:46]        '!DOUBLE[1 -]'
        'feedback_marker', [199]                        '!DOUBLE[1 -]'
       };
opt= opt_setDefaults('bbci.calibrate.settings', props);
                  

bbci.signal.clab= data.cnt.clab(util_chanind(data.cnt, opt.cfy_clab));

mrk_speller = data.mrk; %mrk_selectClasses(data.mrk,opt.cue_markers);

% Error potentials
mrk_errp = data.mrk.classified; % mrk_selectClasses(data.mrk,opt.feedback_marker);
mrk_errp.y(1,:) = mrk_errp.error;
mrk_errp.y(2,:) = ~mrk_errp.error;
mrk_errp.className = {'error' 'correct'};
% Define correct and incorrect trials


%% Speller
bbci.feature(1).proc= {{@proc_baseline, opt.ref_ival, 'beginning_exact'}, ...
                    {@proc_jumpingMeans, opt.cfy_ival}};
bbci.feature(1).ival= [opt.ref_ival(1) opt.cfy_ival(end)];

fv= proc_segmentation(data.cnt, mrk_speller, bbci.feature(1).ival, ...
                      'clab',bbci.signal.clab);
fv= bbci_calibrate_evalFeature(fv, bbci.feature(1));
bbci.classifier(1).C= trainClassifier(fv, opt.model);

%% Error potential
bbci.feature(2).proc= {{@proc_baseline, opt.ref_ival, 'beginning_exact'}, ...
                    {@proc_jumpingMeans, opt.errp_cfy_ival}};
bbci.feature(2).ival= [opt.ref_ival(1) opt.errp_cfy_ival(end)];
fv_errp= proc_segmentation(data.cnt, mrk_errp, bbci.feature(2).ival, ...
                      'clab',bbci.signal.clab);
fv_errp= bbci_calibrate_evalFeature(fv_errp, bbci.feature(2));
bbci.classifier.C= trainClassifier(fv, opt.model);


%%
bbci.control.fcn= @bbci_control_ERP_Speller;
bbci.control.param= {struct_copyFields(opt, {'nClasses', 'nSequences'})};
bbci.control.condition.marker= opt.cue_markers;

bbci.quit_condition.marker= 255;

data.features(1)= fv;
data.features(2)= fv_errp;
