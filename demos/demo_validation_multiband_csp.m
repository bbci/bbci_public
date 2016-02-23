% DEMO_VALIDATION_MULTIBAND_CSP - The demo exemplifies how to use the 
%  crossvalidation function to validate multiband CSP-based classification. 
%  The important issue here is that the CSP analysis has to be performed 
%  WITHIN the cross-validation on each training set. The matrix of spatial 
%  filters that is obtained from the training set needs to be transfered 
%  to the test set. If you would like to know more about such valiation 
%  issues, see [Lemm et al, Neuroimage 2011]. 
%  In the function crossvalidation, there is the possibility to specify
%  processing chains separately for training and test set. Variables obtained
%  from training data may be transfered to the test data. Each step in the
%  processing chain is an application of a 'proc_*' function that transforms
%  the features.
%  Additionally to introducing multiband CSP acting on more than one
%  frequency, it is show how to do crassvalidation with more then one loss
%  measure at a time.


file= fullfile(BTB.DataDir, 'demoMat', 'VPkg_08_08_07', ...
               'calibration_motorimageryVPkg');
[cnt, mrk]= file_loadMatlab(file);
mrk= mrk_selectClasses(mrk, [1 2]);

bands = [4 7; 8 13]; %theta and alpha band
cfy_ival =  [750 3750];
nPatterns = 3;

proc = struct('memo', 'W');
proc.train= {{'W', @proc_multiBandSpatialFilter, {@proc_cspAuto, nPatterns}}
             {@proc_variance}
             {@proc_logarithm}};
proc.apply= {{@proc_multiBandLinearDerivation, '$W'}
             {@proc_variance}
             {@proc_logarithm}};

[filt_b, filt_a] = butters(4,bands/cnt.fs*2);
cnt = proc_filterbank(cnt,filt_b,filt_a);
fv = proc_segmentation(cnt,mrk,cfy_ival);

[losses,lossesem] = crossvalidation(fv,@train_RLDAshrink,...
       'Proc',proc,...
       'SampleFcn',{@sample_chronKFold,8},...
       'LossFcn',{@loss_0_1 @loss_rocArea @loss_classwiseNormalized}); 