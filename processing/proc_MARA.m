function [goodcomp, info] = proc_MARA(cnt_ica,clab,A)
% Usage:
%   [goodcomp, info] = proc_MARA(cnt_ica,clab,A)
%
%  IN   cnt_ica     - data structure of independent components 
%                       cnt_ica.x - [nTimePoint x nComponents]
%                       cnt.fs    - sampling frequency
%       mnt         - electrode montage structure
%       A           - mixing matrix
% 
%  OUT  goodcomp    - array containing the numbers of the non-artifactual 
%                     components
%       info         - struct containing more information about MARA classification 
%               info.out   : continuous output of the classifier
%               info.out_p : out transformed into posterior probablity of being an artifact
%                            P(artifact | out) (assumption normal distribution)
%               info.fv_te : feature values for each tested component
%
% The classifier is based on the following publiction: 
%
% Irene Winkler, Stefan Haufe and Michael Tangermann. Automatic Classification of 
% Artifactual ICA-Components for Artifact Removal in EEG Signals. 
% Behavioral and Brain Functions, 7:30, 2011.
%
% For more information, see: http://www.user.tu-berlin.de/irene.winkler/artifacts/
%
% THIS FUNCTION REQUIRES CLASSIFIER .MAT FILES TO BE INCLUDED IN THE PATH. 
% The data files  <fv_training_MARA.mat>  and  <inv_matrix_icbm152.mat> are
% needed. These can be  can be downloaded with 
% bbci_import_dependencies('MARA')
% or manually from 
% http://www.user.tu-berlin.de/irene.winkler/artifacts/MARAtrdata.zip into  <BTB.Dir>/external/mara

%%%%%%%%%%%%%%%%%%%%
%%  Calculate features 
%%%%%%%%%%%%%%%%%%%%
global BTB
try
    loadData = load(fullfile(BTB.Dir, 'external', 'mara', 'fv_training_MARA.mat'));
    fv_tr = loadData.fv_tr; 
catch
   error(sprintf(['Could not load dependencies of MARA (File fv_training_MARA.mat) \n', ...
       'Make sure that you have have successfully downloaded the requested files with \n', ...
       '> bbci_import_dependencies(''MARA'') \n', ... 
       'or downloaded them manually into <BTB.Dir>/external/mara']))
end

% clabs schneiden
[clab_common i_te i_tr ] = intersect(clab, fv_tr.clab);

% features berechnen
M100 = get_M100(clab_common); 

%high pass filter cnt_ica such that it matches the training data 
pass = 1/(cnt_ica.fs/2);
[b, a] = butter(2, pass, 'high');
cnt_ica = proc_filtfilt(cnt_ica, b, a);

fv_te.x = extract_features(cnt_ica, A(i_te,:), M100);

%%%%%%%%%%%%%%%%%%%%
%%  Adapt train features to clab 
%%%%%%%%%%%%%%%%%%%%
Patterns_tr = fv_tr.pattern(i_tr, :); 
Patterns_tr = Patterns_tr./repmat(std(Patterns_tr ,0,1),length(Patterns_tr (:,1)),1);
fv_tr.x(2,:) = log(max(Patterns_tr) - min(Patterns_tr)); 
fv_tr.x(1,:) = log(sqrt(sum((M100 * Patterns_tr).^2))); 

%%%%%%%%%%%%%%%%%%%%
%%  Classification 
%%%%%%%%%%%%%%%%%%%%

LDA = train_LDA(fv_tr.x, fv_tr.labels);
out = apply_separatingHyperplane(LDA, fv_te.x); 
goodcomp = find(out < 0);

%%%%%%%%%%%%%%%%%%%%
%%  Transform out in probability (assumption: normal distribution)
%%%%%%%%%%%%%%%%%%%%
% out of training data
out_tr = apply_separatingHyperplane(LDA, fv_tr.x); 
% mean and std for neuronal activity 
mu1 = mean(out_tr(find(fv_tr.labels(1,:)))); 
std1 = std(out_tr(find(fv_tr.labels(1,:)))); 
P1 = mean(fv_tr.labels(1,:)); 
% mean and std for artifactual components
mu2 = mean(out_tr(find(fv_tr.labels(2,:)))); 
std2 = std(out_tr(find(fv_tr.labels(2,:)))); 
P2 = mean(fv_tr.labels(2,:)); 

%f(out) where f denotes density function 
f_out = P2/std2 * exp(-1/2*((out-mu2).^2)./(std2.^2)) + ... 
    P1/std1 * exp(-1/2*((out-mu1).^2)./(std1.^2)); 
%f(out|class = artefact)
f_out2 = 1/std2 * exp(-1/2*((out-mu2).^2)./(std2.^2)); 
%P(class = artefact | out) = P(artefact) * f(out|class = artefact) / f(out)
out_p = P2 * f_out2./f_out;  

info.out = out;
info.out_p = out_p;
info.fv_te  = fv_te;


function features = extract_features(cnt, A, M100)
% Usage:
%   features = extract_features(cnt, A, M100)
%
% IN  cnt           - structure of independent component data
%                           cnt.x  - nTimepoints x nComponents array
%                           cnt.fs - sampling frequency
%     A              - mixing matrix A ( nChannels x nComponents ) 
%     M100           - Matrix for source localization, 6426 x  nChannels, 
%                      use function <get_M100> 
% OUT feature_vector - features of the components 
%                            6 x nComponents matrix
%                             - 1st row: Current Density Norm 
%                             - 2nd row: Range Within Pattern
%                             - 3rd row: Average Local Skewness
%                             - 4th row: lambda
%                             - 5th row: Band Power 8 - 13 Hz 
%                             - 6th row: Fit Error
                            


%% standardise the variance of the time series of each component to 1
cnt.x = cnt.x./repmat(std(cnt.x,0,1),length(cnt.x(:,1)),1);

%% standardise the variance of each pattern to 1 
A = A./repmat(std(A,0,1),length(A(:,1)),1);

%% calculate power spectrum (uses utils/proc_spectrum) 
sp_ica = proc_spectrum(cnt, [0, floor(cnt.fs/2)]);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Calculate featues  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for ic=1:length(cnt.x(1,:))  %for each component
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % The average log band power between 8 and 13 Hz
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    p = 0; 
    for i = 8:13 
        p = p + sp_ica.x(find(sp_ica.t == i,1),ic);  
    end
    Hz8_13 = p / (13-8+1);  

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % lambda and FitError: deviation of a component's spectrum from
    % a protoptypical 1/frequency curve 
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    p1.x = 2; %first point: value at 2 Hz
    p1.y = sp_ica.x(find(sp_ica.t == p1.x,1),ic); 

    p2.x = 3; %second point: value at 3 Hz
    p2.y = sp_ica.x(find(sp_ica.t == p2.x,1),ic);

    %third point: local minimum in the band 5-13 Hz
    i = find(sp_ica.t == 5,1); 
    stopp = find(sp_ica.t == 13,1); 
    while sp_ica.x(i,ic) > sp_ica.x(i+1,ic) && i <= stopp
        i = i +1; 
    end
    p3.x = sp_ica.t(i);
    p3.y = sp_ica.x(i,ic); 

    %fourth point: min - 1 in band 5-13 Hz
    p4.x = p3.x - 1;
    p4.y = sp_ica.x(find(sp_ica.t == p4.x,1),ic);
        
    %fifth point: local minimum in the band 33-39 Hz 
    p5.y = min(sp_ica.x(find(sp_ica.t == 33,1):find(sp_ica.t == 39,1),ic));
    p5.x = sp_ica.t(find(sp_ica.x(:,ic) == p5.y,1));

    %sixth point: min + 1 in band 33-39 Hz
    p6.x = p5.x + 1;
    p6.y = sp_ica.x(find(sp_ica.t == p6.x,1),ic);
    
    pX = [p1.x; p2.x; p3.x; p4.x; p5.x; p6.x];
    pY = [p1.y; p2.y; p3.y; p4.y; p5.y; p6.y];
       
    myfun = @(x,xdata)(exp(x(1))./ xdata.^exp(x(2))) - x(3);
    xstart = [4, -2, 54];
        
    fittedmodel = lsqcurvefit(myfun,xstart,pX,pY, [], [], optimset('Display', 'off'));
            
    %FitError: mean squared error of the fit to the real spectrum in the band 8-15 Hz.
    ts_8to15 = sp_ica.t(find(sp_ica.t == 8,1):find(sp_ica.t == 15,1)); 
    fs_8to15 = sp_ica.x(find(sp_ica.t == 8,1):find(sp_ica.t == 15,1),ic)'; 
    fiterror = log(norm(myfun(fittedmodel, ts_8to15)-fs_8to15)^2); 
    
    %lambda: parameter of the fit
    lambda = fittedmodel(2); 
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Averaged local skewness 15s
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    interval = 15; 
    abs_local_scewness = [];
    for i=1:interval:length(cnt.x(:,ic))/cnt.fs-interval
        abs_local_scewness = [abs_local_scewness, abs(skewness(cnt.x(i*cnt.fs:(i+interval)*cnt.fs, ic)))];
    end
    mean_abs_local_scewness_15 = log(mean(abs_local_scewness)); 

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % current density norm
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    norm_dipole_modelling = log(norm(M100*A(:,ic)));

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %SpatialRange
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    spatial_range = log(max(A(:,ic)) - min(A(:,ic)));

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %Append Features 
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   %features(:,ic)= [norm_dipole_modelling, spatial_range,  mean_abs_local_scewness_15, lambda,Hz8_13, fiterror]; 
   features(:,ic)= [norm_dipole_modelling, spatial_range,   ...
       mean_abs_local_scewness_15, lambda, Hz8_13, fiterror]; 
end 


function [M100, idx_clab_desired] = get_M100(clab_desired)
% [M100, idx_clab_desired] = get_M100(clab_desired)
%
% IN  clab_desired - channel setup for which M100 should be calculated
% OUT M100 
%     idx_clab_desired
% M100 is the matrix such that  feature = norm(M100*ica_pattern(idx_clab_desired), 'fro')
%
% Stefan Haufe

lambda = 100;
global BTB
try
    loadData = load(fullfile(BTB.Dir, 'external', 'mara', 'inv_matrix_icbm152.mat'));
    L = loadData.L; %forward matrix 115 x 2124 x 3
    clab = loadData.clab; % corresponding channel labels
catch
    error(sprintf(['Could not load dependencies of MARA (File inv_matrix_icbm152.mat) \n', ...
        'Make sure that you have have successfully downloaded the requested files with \n', ...
        '> bbci_import_dependencies(''MARA'') \n', ... 
        'Or downloaded them manually into <BTB.Dir>/external/mara']))
end

%ICMB 152 atlas
%Copyright (C) 1993?2004 Louis Collins, McConnell Brain Imaging Centre, 
%Montreal Neurological Institute, McGill University. Permission to use, copy, 
%modify, and distribute this software and its documentation for any purpose and 
%without fee is hereby granted, provided that the above copyright notice appear 
%in all copies. The authors and McGill University make no representations about 
%the suitability of this software for any purpose. It is provided ?as is? without
%express or implied warranty. The authors are not responsible for any data loss,
%equipment damage, property loss, or injury to subjects or patients resulting
%from the use or misuse of this software package.
    
[cl_ ia idx_clab_desired] = intersect(clab, clab_desired);
F = L(ia, :, :); %forward matrix for desired channels labels
[n_channels m foo] = size(F);  %m = 2124, number of dipole locations 
F = reshape(F, n_channels, 3*m);

%H - matrix that centralizes the pattern, i.e. mean(H*pattern) = 0
H = eye(n_channels) -  ones(n_channels, n_channels)./ n_channels; 
%W - inverse of the depth compensation matrix Lambda
W = sloreta_invweights(L);

L = H*F*W;

%We have inv(L'L +lambda eye(size(L'*L))* L' = L'*inv(L*L' + lambda
%eye(size(L*L')), which is easier to calculate as number of dimensions is 
%much smaller

%calulate the inverse of L*L' + lambda * eye(size(L*L')
[U D] = eig(L*L');
d = diag(D);
di = d+lambda;
di = 1./di;
di(d < 1e-10) = 0;
inv1 = U*diag(di)*U';  %inv1 = inv(L*L' + lambda *eye(size(L*L'))

%get M100
M100 = L'*inv1*H;
        
    
    
function W = sloreta_invweights(LL)
% inverse sLORETA-based weighting
%
% Synopsis:
%   W = sloreta_invweights(LL);
%   
% Arguments:
%   LL: [M N 3] leadfield tensor
%   
% Returns:
%   W: [3*N 3*N] block-diagonal matrix of weights
%
% Stefan Haufe, 2007, 2008



[M N NDUM]=size(LL);
L=reshape(permute(LL, [1 3 2]), M, N*NDUM);

L = L - repmat(mean(L, 1), M, 1);

T = L'*pinv(L*L');

W = spalloc(N*NDUM, N*NDUM, N*NDUM*NDUM);
for ivox = 1:N
  W(NDUM*(ivox-1)+(1:NDUM), NDUM*(ivox-1)+(1:NDUM)) = (T(NDUM*(ivox-1)+(1:NDUM), :)*L(:, NDUM*(ivox-1)+(1:NDUM)))^-.5;
end

ind = [];
for idum = 1:NDUM
  ind = [ind idum:NDUM:N*NDUM];
end
W = W(ind, ind);


