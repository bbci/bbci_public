function [dat, mrk]= proc_subsampleByLag(dat, lag, mrk)
%PROC_SUBSAMPLEBYLAG - subsampling with specified sampling intervals!
% 
%Synopsis:
%dat= proc_subsampleByLag(dat, lag)
%[dat, mrk]= proc_subsampleByLag(dat, lag, mrk)
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

% bb, ida.first.fhg.de
dat = misc_history(dat);


iv= ceil(lag/2):lag:size(dat.x,1);
dat.x= dat.x(iv,:,:);
dat.fs= dat.fs/lag;

if isfield(dat, 't'),
  dat.t= dat.t(iv);
end

if isfield(dat, 'T'),
  dat.T= dat.T./lag;
end

if nargin>2 && nargout>1,
  mrk.pos= ceil(mrk.pos/lag);
  mrk.fs= mrk.fs/lag;
end
