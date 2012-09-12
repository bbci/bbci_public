function dat = proc_subsampleByLag(dat, lag)
%PROC_SUBSAMPLEBYLAG - subsampling with specified sampling intervals!
% 
%Synopsis:
%dat= proc_subsampleByLag(dat, lag)
%
%Arguments:
%     dat  - data structure of continuous or epoched data
%     lag  - take each 'lag'th sample from input signals
%
%Returns:
%     dat  - updated data structure
% 
% This processing function subsamples an EEG data structure by taking every
% 'lag'th sample from the input signal. The dat.fs is automatically
% updated.
%

if nargin==0,
  dat=[];  return
end

misc_checkType(dat, 'STRUCT(x y)');
misc_checkType(lag,'INT[1]');

dat = misc_history(dat);
%%
iv= ceil(lag/2):lag:size(dat.x,1);
dat.x= dat.x(iv,:,:);
dat.fs= dat.fs/lag;

if isfield(dat, 't'),
  dat.t= dat.t(iv);
end

if isfield(dat, 'T'),
  dat.T= dat.T./lag;
end

