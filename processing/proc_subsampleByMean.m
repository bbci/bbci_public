function [dat, mrk]= proc_subsampleByMean(dat, nSamples, mrk)
%   PROC_SUBSAMPLEBYMEAN  -  subsampling a timeseries by taking the mean
%
%Synopsis
% dat= proc_subsampleByMean(dat, nSamples)
%
%Arguments:
%      dat      - time series
%      nSamples - number of samples from which the mean is calculated
%
%Returns:
%      dat      - processed time series
%
%Description:
% Reduce the sampling rate by subsampling with the mean.
%
%SEE proc_jumpingMeans
dat = misc_history(dat);

dat= proc_jumpingMeans(dat, nSamples);

if nargin>2 & nargout>1,
  mrk.pos= round((mrk.pos-nSamples/2+0.5)/nSamples);
  mrk.fs= mrk.fs/nSamples;
end

