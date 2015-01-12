function dat= proc_subtractMovingAverage(dat, ms, varargin)
%PROC_SUBTRACTMOVINGAVERAGE - Subtract moving average (high-pass) filter
%
%Usage:
% DAT= proc_subtractMovingAverage(DAT, MSEC, <METHOD='causal'>)
%
%Input:
% DAT    - data structure of continuous or epoched data
% MSEC   - length of interval in which the moving average is
%          to be calculated, unit [msec].
% METHOD - 'centered' or 'causal' (default).
%
%Output:
% DAT    - updated data structure

% Author(s): Benjamin Blankertz


misc_checkType(dat, 'STRUCT(x fs)');
misc_checkType(ms, '!DOUBLE[1]');

nSamples = round(ms*dat.fs/1000);
sx= size(dat.x);
xa= procutil_movingAverage(dat.x(:,:), nSamples, varargin{:});
dat.x= dat.x - reshape(xa, sx);
