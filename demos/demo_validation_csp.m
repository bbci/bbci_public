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
                'SampleFcn', {@sample_chronKKfold, 8}, ...
                'Proc', proc);
