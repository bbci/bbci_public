function out= proc_dBAverage(epo, varargin)
%PROC_DBAVERAGE - Classwise calculated averages for dB-scaled features
%
%This functions is exactly used as proc_average. It should be used
%for dB-scaled features (e.g. output of proc_power2dB; or
%proc_spectrum in the default setting 'scaling', 'dB').
if nargin==0,
  out= proc_average; return;
end

epo = misc_history(epo);
out= epo;
%% scale back
out.x= 10.^(epo.x/10);
out= rmfield(out, 'yUnit');  % otherwise we will enter an infinite recursion

%% average
out= proc_average(out, varargin{:});

%% re-convert to dB
out.x= 10*log10(out.x);
out.yUnit= 'dB';
