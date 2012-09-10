function [cnt,state]= online_filterbank(cnt, state, filt_b, filt_a)
%ONLINE_FILTBANK - apply several digital (FIR or IIR) forward filters to online data
%
% Synopsis:
%[cnt,state]= online_filterbank(cnt, state, filt_b, filt_a)
%
%Arguments:
%   cnt:    data structure of continuous data
%   state:  filter state 
%   filt_b, filt_a:    CELL [1xN] - cell arrays of 
%      filter coefficients as obtained by buttersfilter coefficients
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
%Example:
%
%
% SEE butters, online_filt, proc_filterbank

% Benjamin Blankertz


if isempty(state),
  state.nFilters= length(filt_b);
  state.filt_b= filt_b;
  state.filt_a= filt_a;
  persistent xo;       %% reserve memory only once
  [T, state.nChans]= size(cnt.x);
  xo= zeros([T, state.nChans*state.nFilters]);
  state.filtstate= cell([1 state.nFilters]);
%  state.clab= cell(1, state.nChans*state.nFilters);
%  cc= 1:state.nChans;
%  for ii= 1:state.nFilters,
%    state.clab(cc)= strcat(cnt.clab, ['_flt' int2str(ii)]);
%    cc= cc + state.nChans;
%  end
end

cc= 1:state.nChans;
for ii= 1:state.nFilters,
  [xo(:,cc), state.filtstate{ii}]= ...
     filter(state.filt_b{ii}, state.filt_a{ii}, cnt.x, state.filtstate{ii}, 1);
  cc= cc + state.nChans;
end
cnt.x= xo;
%cnt.clab= state.clab;
