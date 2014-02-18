function dat= proc_envelope(dat, varargin)
%PROC_ENVELOPE - Envelope Curve of Oscillatory Signals
%
%Synopsis:
% DAT= proc_envelope(DAT, <OPT>)
%
%Arguments:
% DAT: data structure, continuous or epoched signals.
% OPT: struct or property/value list of optinal properties
%  .EnvelopMethod: 'hilbert' (only choice so far)
%  .MovAvgMethod: 'centered' (default) or 'causal'
%  .MovAvgMsec: window length [msec] for moving average, deafult: 100.
%  .Channelwise: useful in case of memory problems
%
%Returns:
% DAT: output data structure, continuous or epoched as input
%      signals are the envelope curves of inut signals
% 
%Description:
% This function computes the envelope Curve of oscillarory signals. This is
% useful to estimate changes in power of over time. 
%
% SEE ALSO proc_spectrogram, proc_fft, proc_variance

% Author(s): Benjamin Blankertz
% added channelwise option by Claudia
% 07-2012 Johannes Hoehne - Updated documentation and parameter naming
props= {'EnvelopMethod'   'hilbert'    '!CHAR(hilbert)'
        'MovAvgMethod'    'centered'   '!CHAR(centered causal)'
        'MovAvgMsec'      100          'DOUBLE[1]'
        'MovAvgOpts'      {}           'CELL'
        'Channelwise'     false        'BOOL'
       };
if nargin==0,
  dat= props; return
end

if length(varargin)==1,
  opt= struct('appendix', varargin{1});
else
  opt= opt_proplistToStruct(varargin{:});
end

dat = misc_history(dat);
[opt, isdefault]= opt_setDefaults(opt, props);
opt_checkProplist(opt, props);

sz= size(dat.x);
switch(lower(opt.EnvelopMethod)),
 case 'hilbert',
  if opt.Channelwise
    for ch = 1:sz(2)
      x(:,ch,:) = abs(hilbert(squeeze(dat.x(:,ch,:))));
    end
    dat.x = x;
  else
    dat.x= abs(hilbert(dat.x(:,:)));     
    dat.x= reshape(dat.x, sz);
  end
  
 otherwise,
  error('unknown envelop method');
end

if ~isempty(opt.MovAvgOpts),
  dat= proc_movingAverage(dat, opt.MovAvgMsec, opt.MovAvgOpts{:});
elseif ~isempty(opt.MovAvgMsec) && opt.MovAvgMsec>0,
  dat= proc_movingAverage(dat, opt.MovAvgMsec, opt.MovAvgMethod);
end
