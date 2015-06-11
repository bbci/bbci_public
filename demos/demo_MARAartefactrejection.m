% This demo shows the working steps for artefact reduction using MARA. 
% It requires 
%    - the function <fastica.m>  
%    - the data fiels which contain the classifier, 
%       <fv_training_MARA.mat>  and  <inv_matrix_icbm152.mat>
%       http://www.user.tu-berlin.de/irene.winkler/artifacts/MARAtrdata.zip

eeg_file= fullfile(BTB.DataDir, 'demoMat', 'VPiac_10_10_13', ...
                   'calibration_CenterSpellerMVEP_VPiac');

% Load data
try
  [cnt, mrk, mnt] = file_loadMatlab(file);
catch
  error('You need to run ''demo_convert_ERPSpeller'' first');
end

%High-pass filter the data (ICA otherwise finds drifts)
high_pass_fs = 1; %at 1 Hz in this example
[b, a] = butter(2, high_pass_fs/(cnt.fs/2), 'high');
cnt = proc_filtfilt(cnt, b, a);

%Do FastICA
[icasig, A_ica, W_ica] = fastica(cnt.x'); % 'maxNumIterations', 50);
cnt_ica = cnt; cnt_ica.x = cnt.x *W_ica';

%Classify components (artefact vs. neuro) using MARA
disp('MARA Artefact Classification ...')
[goodcomp, info] = proc_MARA(cnt_ica,mnt.clab,A_ica); 
fprintf('MARA identified %d artifactual components. \n', ... ...
        length(A_ica(1,:))- length(goodcomp)); 
fprintf('Kept %d components \n',length(goodcomp));

%Plot each classified components to check if ICA separation and MARA 
%classification was successful 
plot_BSScomponents(cnt_ica, mnt, W_ica, A_ica, 'goodcomp', goodcomp, 'out', info.out_p);

%Remove activity to get (hopefully) cleaner EEG signals: Reconstruct EEG
%only with the good components in goodcomp
cnt_clean = cnt; 
cnt_clean.x =  cnt.x * W_ica(goodcomp, :)' * A_ica(:, goodcomp)';
