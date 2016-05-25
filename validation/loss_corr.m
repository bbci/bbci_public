function loss = loss_corr(label, out)
%LOSS_CORR - correlation between true labels and predicted labels. Note
%           that this is technically not a loss function (in the sense that 
%           it has to be minimized) because large negative or large positive 
%           correlations could be desired. 
%
%Synopsis:
% LOSS= loss_corr(LABEL, OUT)
%
% IN  LABEL - vector of true values, size [1 nSamples]
%     OUT   - vector predictor outputs, i.e. predicted values
%                   
% OUT LOSS  - correlation between LABEL and OUT
%
% SEE crossvalidation

% Sven Daehne


R = corrcoef(label', out');
loss = R(1,2);
