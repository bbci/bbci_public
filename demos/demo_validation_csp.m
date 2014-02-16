% DEMO_VALIDATION_CSP - The demo exemplifies how to use the crossvalidation
%  function to validate CSP-based classification. The important issue here
%  is that the CSP analysis has to be performed WITHIN the cross-validation
%  on each training set. The matrix of spatial filters that is obtained from
%  the training set needs to be transfered to the test set. If you would like
%  to know more about such valiation issues, see [Lemm et al, Neuroimage
%  2011]. 
%  In the function crossvalidation, there is the possibility to specify
%  processing chains separately for training and test set. Variables obtained
%  from training data may be transfered to the test data. Each step in the
%  processing chain is an application of a 'proc_*' function that transforms
%  the features.


file= fullfile(BTB.DataDir, 'demoMat', 'VPkg_08_08_07', ...
               'calibration_motorimageryVPkg');
[cnt, mrk]= file_loadMatlab(file);
mrk= mrk_selectClasses(mrk, [1 2]);

[filt_b,filt_a]= butter(5, [9 13]/cnt.fs*2);
cnt= proc_filt(cnt, filt_b, filt_a);
fv= proc_segmentation(cnt, mrk, [750 3750]);

proc.train= {{'CSPW', @proc_cspAuto, 3}
             @proc_variance
             @proc_logarithm
            };
proc.apply= {{@proc_linearDerivation, '$CSPW'}
             @proc_variance
             @proc_logarithm
            };

crossvalidation(fv, {@train_RLDAshrink, 'Gamma',0}, ...
                'SampleFcn', {@sample_chronKFold, 8}, ...
                'Proc', proc)
