function ci = cspselect_directorsCut(score, ~, maxNrComps)
%CSPSELECT_DIRECTORSCUT - Heuristically select components
%
%Synopsis:
% CI = select_directorsCut(SCORE, ~, MAXNRCOMPS)
%
%Arguments:
% SCORE      - score of components
% MAXNRCOMPS - maximal number of components per class (optional)
% 
%Returns:
% CI     - index of components
%
%Description:
% Components are selected according to a heuristic, such that each class is
% represented at least with one component and maximally maxNrComps
% components are selected pre class.
%
%See also processing/proc_csp

nChans = length(score);
Nh = floor(nChans/2);

if not(exist('maxNrComps','var'))
    maxNrComps = Nh-1;
else
    maxNrComps = min(maxNrComps,Nh-1);
end

absscore = abs(score);
[~,ix]= sort(score);

iC1 = find(ismember(ix, 1:Nh,'legacy'));
iC2 = flipud(find(ismember(ix,nChans-Nh+1:nChans,'legacy')));

iCut = find(absscore(ix)>=0.66*max(absscore));

idx1 = [iC1(1); intersect(iC1(2:maxNrComps),iCut,'legacy')];
idx2 = [iC2(1); intersect(iC2(2:maxNrComps),iCut,'legacy')];
ci = ix([idx1; flipud(idx2)]);