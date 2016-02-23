%% This demo demonstrates how to validate a feature selection method
% It shows by no means a sophisticated way to select features, the
% focus is just to show how to do the validation.

% Run demo_analysis_ERPs to load and preprocess the data
%{
demo_analysis_ERPs
%}

%% This is the 'fake' variant:
ivals = procutil_selectTimeIntervals(epo_r, 'NIvals',7);
fv=proc_jumpingMeans(epo,ivals);
loss=crossvalidation(fv, @train_RLDAshrink, 'SampleFcn',{@sample_KFold, [1 10]});
disp(['Fake loss: ' num2str(loss)])


%% This is the correct validation: select features WITHIN the cross-validation
% on each training set and evaluate this selection on the test set. To do 
% this you have to have separate processings for the training set and for 
% the test set .

fv=epo;

% The crossvalidation scheme is adapted and simplified from 
% validation/crossvalidation.m.
% Please have a look on this function if you want to run a 
% crossvalidation with shuffles, e.g. a 10 x 10 crossvalidation.
trainFcn=@train_RLDAshrink;
applyFcn= @apply_separatingHyperplane;
[sampleFcn, samplePar]= misc_getFuncParam({@sample_KFold, [1 10]});
[divTr, divTe]= sampleFcn(fv.y, samplePar{:});
lossFcn=@loss_0_1;

nFolds= length(divTr{1});
fold_loss= zeros(nFolds, 1);

for ff= 1:nFolds,
    fprintf('Fold: %i of %i\n', ff, nFolds) % display progress...
    
    % Indices of training and test data of the current cross fold
    idxTr= divTr{1}{ff};
    idxTe= divTe{1}{ff};
        
    % Select training data of the current cross fold
    fvTr= proc_selectSamples(fv, idxTr);
    
    % Feature selection using training data
    separability_values = proc_rSquareSigned(fvTr);
    ivals = procutil_selectTimeIntervals(separability_values, 'NIvals',7);
    fvTr=proc_jumpingMeans(fvTr,ivals);

    % Train classifier on training data
    xsz= size(fvTr.x);
    fvsz= [prod(xsz(1:end-1)) xsz(end)];
    C= trainFcn(reshape(fvTr.x,fvsz), fvTr.y);
    
    % Select test data of the current cross fold
    fvTe= proc_selectSamples(fv, idxTe);
    
    % Feature selection from test data using the intervals determined on training data
    fvTe=proc_jumpingMeans(fvTe,ivals);
    
    % Apply classifier function (determined using training data) to the test data
    xsz= size(fvTe.x);
    out= applyFcn(C, reshape(fvTe.x, [prod(xsz(1:end-1)) xsz(end)]));
    
    % Determine classification loss
    fold_loss(ff)= mean(lossFcn(fvTe.y, out));
end

loss = mean(fold_loss);
disp(['Correct loss: ' num2str(loss)])