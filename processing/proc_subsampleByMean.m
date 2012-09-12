function dat = proc_subsampleByMean(dat, nSamples)
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
%See also proc_jumpingMeans
if nargin==0
  dat=[];return
end

misc_checkType(dat, 'STRUCT(x)');
misc_checkType(nSamples,'DOUBLE[1]');
dat = misc_history(dat);

dat= proc_jumpingMeans(dat, nSamples);


