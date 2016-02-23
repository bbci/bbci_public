function idx= procutil_selectMinMax(score, W, nComponents)
% Just for testing - will be replaced by a function of MSK
% (with different name)

idx= [1:nComponents, length(score)-nComponents+1:length(score)]';
