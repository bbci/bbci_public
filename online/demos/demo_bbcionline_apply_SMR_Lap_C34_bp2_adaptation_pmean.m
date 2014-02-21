% DEMO_BBCIONLINE_APPLY_SMR_LAP_C34_BP2_ADAPTATION_PMEAN
%  This script demonstrates how to train a classifier 'by hand'
%  (meaning without a calibration function), and to setup an online
%  processing chain using unsupervised adaptation.
%  In the typical use case, most of these things are done by a calibrate
%  function (bbci_calibrate). But adaptation has to be added manually
%  to the processing chain.

BTB_memo= BTB;
BTB.MatDir= fullfile(BTB.DataDir, 'demoMat');

% load calibration data
file= fullfile('VPkg_08_08_07', ...
               'calibration_motorimageryVPkg');
[cnt, mrk]= file_loadMatlab(file, 'vars',{'cnt','mrk'});
mrk= mrk_selectClasses(mrk, {'left','right'});

% and calculate a Shrinkage-LDA classifier on log band-power features
% in Laplacian channels C3, C4.
% (this is doing the calibration by hand)
clab= procutil_getClabForLaplacian(cnt, 'C3,4');
fv= proc_selectChannels(cnt, clab);
[fv, A]= proc_laplacian(fv, 'clab','C3,4');
[filt_b, filt_a]= butters(5, [9 13; 18 26]/cnt.fs*2);
fv= proc_filterbank(fv, filt_b, filt_a);
fv= proc_segmentation(fv, mrk, [750 3500]);
fv= proc_variance(fv);
fv= proc_logarithm(fv);
fv= proc_flaten(fv);
classy= {@train_RLDAshrink, 'StoreMeans', 1};
C= trainClassifier(fv, classy);

% load feedback data
file= fullfile('VPkg_08_08_07', ...
               'feedback_motorimageryVPkg');
[cnt, mrk]= file_loadMatlab(file, 'vars',{'cnt','mrk'});

% and setup the online processing chain with an unsupervised adaptation
% method, see [Vidaurre et al, IEEE TBME 2011].
bbci= struct;
bbci.source.acquire_fcn= @bbci_acquire_offline;
bbci.source.acquire_param= {cnt, mrk.orig};

bbci.signal.clab= clab;
bbci.signal.proc= {{@online_linearDerivation, A},
                   {@online_filterbank, filt_b, filt_a}};

bbci.feature.proc= {@proc_variance, @proc_logarithm};
bbci.feature.ival= [-500 0];

bbci.classifier.C= C;

bbci.adaptation.active= 1;
bbci.adaptation.fcn= @bbci_adaptation_pmean;
bbci.adaptation.param= {'ival', [500 4000]};
bbci.adaptation.log.output= 'screen';

bbci.quit_condition.marker= 254;

bbci_apply(bbci);

BTB= BTB_memo;
