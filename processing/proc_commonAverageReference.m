function [dat, A]= proc_commonAverageReference(dat, refChans, rerefChans)
%PROC_COMMONAVERAGEREFERENCE - rereferencing to a common reference
%
%Synopsis:
% dat= proc_commonAverageReference(dat, <refChans, rerefChans>)
%
% rereference signals to common average reference. you should only
% used scalp electrodes as reference, not e.g. EMG channels.
%
%Arguments:
%      dat        - data structure of continuous or epoched data
%      refChans   - channels used as average reference, 
%                   see util_chanind for format, 
%                   default util_scalpChannels(dat)
%      rerefChans - those channels are rereferenced, default refChans
%
%Returns:
%      dat        - updated data structure
%
% SEE util_scalpChannels, util_chanind


dat = misc_history(dat);

misc_checkType(dat, 'STRUCT(x clab)'); 

if ~exist('refChans','var') || isempty(refChans)
  refChans= dat.clab(util_scalpChannels(dat));
end
if ~exist('rerefChans','var') || isempty(rerefChans), 
  rerefChans= refChans; 
end

misc_checkType(refChans, 'CELL{CHAR}|CHAR'); 
misc_checkType(rerefChans, 'CELL{CHAR}|CHAR'); 

rc= util_chanind(dat, refChans);
rrc= util_chanind(dat, rerefChans);
car= mean(dat.x(:,rc,:), 2);

nChans= size(dat.x,2);
A= eye(nChans, nChans);
A(rc,rrc)= A(rc,rrc) - 1/length(rc);
dat= proc_linearDerivation(dat, A, 'CLab','copy', 'Appendix',' car');
