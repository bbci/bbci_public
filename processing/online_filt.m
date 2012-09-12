function [dat,state]= online_filt(dat, state, b, a, varargin)
%ONLINE_FILT - apply digital (FIR or IIR) forward filter(s) to online data
%
%Synopsis:
%[cnt,state]= online_filt(cnt, state, b, a, <b2, a2, ...>)
%
%Arguments:
%   cnt:    data structure of continuous data
%   state:  filter state 
%   b, a:    DOUBLE [1xN] - filter coefficients
%
%Returns:  
%   cnt:    updated data structure
%   state:  updated filter state 
%
%Description:
% This function applies forward frequency filtering to online data. 
% Those filters and the corresponding filter coefficients (a,b) can 
% be generated with e.g. Butterworth or Chebyshev filter design.
%
%
% SEE online_filterbank for applying multiple filters in parallel

% Benjamin Blankertz

[dat.x, state] = filter(b, a, dat.x, state, 1);
