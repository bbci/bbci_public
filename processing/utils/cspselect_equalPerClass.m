function idx= cspselect_equalPerClass(score, ~, nComponents)
%CSPSELECT_EQUALPERCLASS - Select equally many CSP components for each class
%
%Synopsis:
% CI = select_fixedNumber(SCORE, ~, NCOMP)
%
%Arguments:
% SCORE  - score of components
% NCOMPS - number of components (total number depends on MODE)
% 
%Returns:
% CI     - index of components
%
%See also processing/proc_csp


idx= [1:nComponents, length(score)-nComponents+1:length(score)]';
