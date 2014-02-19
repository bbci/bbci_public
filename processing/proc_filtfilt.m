function dat= proc_filtfilt(dat,varargin)
%PROC_FILTFILT - Zero-phase forward and reverse digital filtering
%
%Synopsis:
% DAT= proc_filtfilt(DAT, B, A)
%
% Apply digital (FIR or IIR) filter forward and backward
% -> zero-phase filter. This filtering is not causal!
%
%Arguments:
% DAT   - data structure of continuous or epoched data
% B,A   - filter coefficients
%
%
%Returns:
% DAT   - updated data structure
%
%Example(1):
% % Let cnt be a structure of multi-variate time series ('.x', time along first
% % dimension) with sampling rate specified in field '.fs'.
% [b,a]= butter(5, [7 13]/cnt.fs*2);
% % Apply a zero-phase band-pass filter 7 to 13Hz to cnt:
% cnt_flt= proc_filtfilt(cnt, b, a);
%
%
%See also proc_filt.

dat = misc_history(dat);
misc_checkType(dat, 'STRUCT(x)'); 

if size(varargin,2) == 1
  varargin= cat(2, varargin, {1});
end
dat.x(:,:)= filtfilt(varargin{1}, varargin{2}, dat.x(:,:));
