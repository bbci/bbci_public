function [dat,state]= online_subtractMovingAverage(dat, state, ms,varargin)
%ONLINE_SUBSTRACTMOVINGAVERAGE - online substraction of the moving average
%
%Synopsis
% [dat,state]= state_subtractMovingAverage(dat,state, msec, <method='centered'>)
%
%Arguments:
%      dat    - data structure of continuous or epoched data
%      msec   - length of interval in which the moving average is
%               to be calculated in msec
%      method - 'centered' or 'causal' (default)
%
%Returns:
%      dat    - updated data structure
%

[dat2,state] = online_movingAverage(dat,state,ms,varargin{:});

dat.x = dat.x-dat2.x;

