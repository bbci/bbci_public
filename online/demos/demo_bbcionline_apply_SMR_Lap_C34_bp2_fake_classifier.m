% EEG file used of offline simulation of online processing
eeg_file= 'VPkg_08_08_07/imag_arrowVPkg';

[cnt, mrk_orig]= file_loadMatlab(eeg_file, 'vars',{'cnt','mrk_orig'});
%% --- transitional
mrk_orig.time= mrk_orig.pos*1000/mrk_orig.fs;
mrk_orig= rmfield(mrk_orig, 'fs');
% -----

clab= procutil_getClabForLaplacian(cnt, 'C3,4');
tmp= proc_selectChannels(cnt, clab);
[tmp, A]= proc_laplacian(tmp, 'clab','C3,4');
[filt_b, filt_a]= butters(5, [9 13; 18 26]/cnt.fs*2);
C= struct('b', 0);
C.w= randn(size(A,2)*2, 1);  % 2 log-bandpower feature per channel

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

bbci_apply(bbci);
