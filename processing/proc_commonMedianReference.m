function dat= proc_commonMedianReference(dat, refChans, rerefChans)
%PROC_COMMONMEDIANREFERENCE - rereference signals to common median reference
%
%Synopsis:
% dat= proc_commonMedianReference(dat, <refChans, rerefChans>)
%
%
%Arguments:
%      dat        - data structure of continuous or epoched data
%      refChans   - channels used as average reference, see chanind for format, 
%                   default scalpChannels(dat)
%      rerefChans - those channels are rereferenced, default refChans
%
%Returns:
%      dat        - updated data structure
%
% SEE scalpChannels, chanind

% Author: Benjamin Blankertz
dat = misc_history(dat);


if ~exist('refChans','var') | isempty(refChans),
  refChans= scalpChannels(dat);
end
if ~exist('rerefChans','var') | isempty(rerefChans), rerefChans= refChans; end

rc= chanind(dat, refChans);
rrc= chanind(dat, rerefChans);
car= median(dat.x(:,rc,:), 2);
%% this might consume too much memory:
%car= repmat(car, [1 length(rrc) 1]);
%dat.x(:,rrc,:)= dat.x(:,rrc,:) - car;

for cc= rrc,
  dat.x(:,cc,:)= dat.x(:,cc,:) - car;
  dat.clab{cc}= [dat.clab{cc} ' car'];
end
