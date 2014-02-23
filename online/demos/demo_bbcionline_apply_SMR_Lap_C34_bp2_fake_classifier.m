% DEMO_BBCIONLINE_APPLY_SMR_LAP_C34_BP2_ADAPTATION_PMEAN
%  This script demonstrates how setup an online processing for
%  SMR modulations.
%  In the typical use case, these things are done by a calibrate
%  function (bbci_calibrate). But for educations reasons it is good to
%  know how these things work.


% load calibration data
file= fullfile(BTB.DataDir, 'demoMat', 'VPkg_08_08_07', ...
               'calibration_motorimageryVPkg');
[cnt, mrk]= file_loadMatlab(file, 'vars',{'cnt','mrk'});

% this is just stuff to get some variables that are used below to
% define the online processing chain.
clab= procutil_getClabForLaplacian(cnt, 'C3,4');
tmp= proc_selectChannels(cnt, clab);
[tmp, A]= proc_laplacian(tmp, 'clab','C3,4');
[filt_b, filt_a]= butters(5, [9 13; 18 26]/cnt.fs*2);
C= struct('b', 0);
C.w= randn(size(A,2)*2, 1);  % 2 log-bandpower feature per channel

% setup the bbci variable to define the online processing chain
bbci= struct;
bbci.source.acquire_fcn= @bbci_acquire_offline;
bbci.source.acquire_param= {cnt, mrk.orig};

bbci.signal.clab= clab;
bbci.signal.proc= {{@online_linearDerivation, A},
                   {@online_filterbank, filt_b, filt_a}};

bbci.feature.proc= {@proc_variance, @proc_logarithm};
bbci.feature.ival= [-500 0];

bbci.classifier.C= C;

bbci_apply(bbci);
