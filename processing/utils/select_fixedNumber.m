
function ci = select_fixedNumber(score,~,nComps,mode)
%SELECT_FIXEDNUMBER - Select a fixed number of components
%
%Synopsis:
% CI = select_fixedNumber(SCORE,~,NCOMPS,MODE)
%
%Arguments:
% SCORE  - score of components
% NCOMPS - number of components (total number depends on MODE)
% MODE   - 'absolutemax' : chooses NCOMPS components corresponding to the
%          NCOMPS maximal absolute scores)
%          'equalperclass' : chooses 2*NCOMPS components corresponding to
%          the NCOMPS lowest and the NCOMPS highest scores (default)
%          'onlyclass1' : chooses NCOMPS components corresponding to the
%          NCOMPS lowest scores
%          'onlyclass2' : chooses NCOMPS components corresponding to the
%          NCOMPS highest scores
% 
%Returns:
% CI     - index of components
%
%See also processing/proc_csp

nChans = length(score);

switch mode
    case 'absolutemax'
        [~,ix] = sort(-abs(score));
        ci = ix(1:nComps);
    case 'equalperclass'
        [~,ix] = sort(score);
        ci = [ix(1:nComps); ix(end:-1:nChans-nComps+1)];
    case 'onlyclass1'
        [~,ix] = sort(score);
        ci = ix(1:nComps);
    case 'onlyclass2'
        [~,ix] = sort(score);
        ci = ix(end:-1:nChans-nComps+1);
    otherwise
        error('Unknown mode')
end