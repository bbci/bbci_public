function C = train_logisticRegression(XTr, YTr)
% TRAIN_LOGISTICREGRESSION - Logistic regresion classifier
%
%Synopsis:
%   C = train_logisticRegression(XTr, YTr)
%
%Arguments:
%   XTR: DOUBLE [NxM] - Data matrix, with N feature dimensions, and M training points/examples. 
%   YTR: INT [CxM] - Class membership labels of points in X_TR. C by M matrix of training
%                     labels, with C representing the number of classes and M the number of training examples/points.
%                     Y_TR(i,j)==1 if the point j belongs to class i.
%Returns:
%   C: STRUCT           - Structure containing the b coefficients of the logit model, trained on the data.
%                             The structure C includes the field:
%       'b': STRUCT     - coefficients of the classifier
%
%Description:
%   TRAIN_LOGISTICREGRESSION trains a logisctic regression classifier given training data and labels.
%

%
%
%Examples:
%     train_logisticRegression(XTr, YTr)
%   
%See also:
%   APPLY_LOGISTICREGRESSION

misc_checkType(XTr, 'DOUBLE[- -]');
misc_checkType(YTr, 'DOUBLE[2 -]');

B = mnrfit(XTr', categorical(YTr(1,:))');

C.b = B;
