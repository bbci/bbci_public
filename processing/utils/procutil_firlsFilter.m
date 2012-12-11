function [b, a]= procutil_firlsFilter(freq, fs, varargin)
%PROCUTIL_FIRLSFILTER - Get coefficients of an FIR-ls filter
%
%Synopsis:
%  [B, A]= procutil_firlsFilter(FREQ, FS, <OPT>)
%
%Arguments:
%  FREQ - Determines the edge frequency/cies of the filter. If
%     FREQ is a two-element vector, a band-pass filter is designed.
%     If FREQ is a scalar, by default a high-pass filter is designed.
%  FS - Sampling rate
%  OPT - Struct or property/value list of optional properties:
%    .Lowpass
%
%Returns:
%  A = 1 and
%  B: Filter coefficients of the FIR filter. Can be used with the
%    matlab filtering functions filter and filtfilt, as well as
%    with proc_filt, proc_filtfilt
%
%
%The algorithm to determine the settings was taken from the function
%eegfilt of the eeglab toolbox by Scott Makeig and Arnaud Delorme.
%
%Advice by Scott: When a bandpass filter is unstable, first highpass,
%  then lowpass filtering the data may work.

%        Benjamin Blankertz
% 07-2012 Johannes Hoehne - Updated documentation and parameter naming


props= {'Lowpass'   0
        'Bandstop'  0
        'Order'     []
        'Minorder'  15
        'Trans'     0.15};

if nargin==0,
  b = props; a= []; return
end

opt= opt_proplistToStruct(varargin{:});
[opt, isdefault]= opt_setDefaults(opt, props);
opt_checkProplist(opt, props);


nyq= fs/2;
if isempty(opt.Order),
  opt.Order= max(opt.Minorder, 3*fix(fs/min(freq)));
end

if length(freq)==1 && ~opt.Lowpass,
  f= [0 freq*(1-opt.Trans)/nyq freq/nyq 1];
  amp= [0 0 1 1];
elseif length(freq)==1 && opt.Lowpass,
  f= [0 freq/nyq freq*(1+opt.Trans)/nyq 1];
  amp= [1 1 0 0];
elseif length(freq)==2 && ~opt.Bandstop,
  f= [0 freq(1)*(1-opt.Trans)/nyq freq(1)/nyq ...
      freq(2)/nyq freq(2)*(1+opt.Trans)/nyq 1];
  amp= [0 0 1 1 0 0];
elseif length(freq)==2 && opt.Bandstop,
  f= [0 freq(1)*(1-opt.Trans)/nyq freq(1)/nyq ...
      freq(2)/nyq freq(2)*(1+opt.Trans)/nyq 1];
  amp= [1 1 0 0 1 1];
end

b= firls(opt.Order, f, amp);
a= 1;
