% EEG file used for offline simulation of online processing
eeg_file= 'VPkg_08_08_07/imag_arrowVPkg';
[cnt, mrk]= file_loadMatlab(eeg_file, 'vars',{'cnt','mrk'});
%% --- transitional
mrk= convert_markers(mrk);
% -----

S.bbci= file_loadMatlab(eeg_file, 'vars','bbci');
mrk = mrk_selectClasses(mrk, S.bbci.classes);

clab= procutil_getClabForLaplacian(cnt, 'C3,4');
fv= proc_selectChannels(cnt, clab);
[fv, A]= proc_laplacian(fv, 'clab','C3,4');
[filt_b, filt_a]= butters(5, [9 13; 18 26]/cnt.fs*2);
fv= proc_filterbank(fv, filt_b, filt_a);
fv= proc_segmentation(fv, mrk, S.bbci.setup_opts.ival);
fv= proc_variance(fv);
fv= proc_logarithm(fv);
fv= proc_flaten(fv);
classy= {@train_RLDAshrink, 'StoreMeans', 1};
C= trainClassifier(fv, classy);

eeg_file= 'VPkg_08_08_07/imag_fbarrowVPkg';
[cnt, mrk_orig]= file_loadMatlab(eeg_file, 'vars',{'cnt','mrk_orig'});
%% --- transitional
mrk_orig.time= mrk_orig.pos*1000/mrk_orig.fs;
mrk_orig= rmfield(mrk_orig, 'fs');
% -----

bbci= struct;
bbci.source.acquire_fcn= @bbci_acquire_offline;
bbci.source.acquire_param= {cnt, mrk_orig};
bbci.source.marker_mapping_fcn= @bbciutil_markerMappingSposRneg;

bbci.signal.clab= clab;
bbci.signal.proc= {{@online_linearDerivation, A},
                   {@online_filterbank, filt_b, filt_a}};

bbci.feature.proc= {@proc_variance, @proc_logarithm};
bbci.feature.ival= [-500 0];

bbci.classifier.C= C;

bbci.adaptation.active= 1;
bbci.adaptation.fcn= @bbci_adaptation_pmean;
bbci.adaptation.param= {struct('ival',[500 4000])};
bbci.adaptation.filename= '$BTB.TmpDir/bbci_classifier_pmean';
bbci.adaptation.log.output= 'screen';

bbci.quit_condition.marker= 254;

bbci_apply(bbci);
