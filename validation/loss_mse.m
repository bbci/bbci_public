function loss = loss_mse(label, out)
%LOSS_MSE - Loss function: mean squared error
%
%Synopsis:
% LOSS= loss_MSE(LABEL, OUT)
%
% IN  LABEL - vector of true values, size [1 nSamples]
%     OUT   - vector predictor outputs, i.e. predicted values
%                   
% OUT LOSS  - averaged squared difference between LABEL and OUT
%
% SEE crossvalidation

% Sven Daehne

loss = mean((label - out).^2);

