%This directory contains scripts for training classifiers and to apply trained classifiers to data
%
%
%APPLYCLASSIFIER - Apply a pre-trained classifier model to a collection of data (FV)
%                       
%APPLY_SEPARATINGHYPERPLANE - Special case of APPLYCLASSIFIER, 
%                             where the classifier is a linear separating hyperplane (e.g. LDA classifier)
%MISC_GETAPPLYFUNC - Given a pre-trained classifier, you can determine the
%                    function call to apply this classifier
%TRAINCLASSIFIER - Given a collection of data (FV), and a type of classifier model, 
%                  the classifier is trained, i.e. the free parameters of the model are determined
%TRAIN_RLDASHRINK - Special case of TRAINCLASSIFIER: classifier is a LDA model 
%                   (linear discriminant analysis). Good initial choice to try on a new classification problem.
%TRAIN_RLDASHRINK - Special case of TRAINCLASSIFIER: classifier is a LDA model 
%                   (linear discriminant analysis), and shrinkage of the estimated covariance is 
%                   used for regularization. Good initial choice to try on a new classification problem.
%TRAIN_SWLDAMATLAB - Special case of TRAINCLASSIFIER: classifier is a stepwise-linear LDA model. 
%                    Regularization not built-in, thus beware of overfitting.
