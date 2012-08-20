function dat= proc_envelope(dat, varargin)
%PROC_ENVELOPE - Envelope Curve of Oscillatory Signals
%
%Synopsis:
% DAT= proc_envelope(DAT, <OPT>)
%
%Arguments:
% DAT: data structure, continuous or epoched signals.
% OPT: struct or property/value list of optinal properties
%  .envelopMethod: 'hilbert' (only choice so far)
%  .movAvgMethod: 'centered' (default) or 'causal'
%  .movAvgMilisec: window length [msec] for moving average, deafult: 100.
%  .channelwise: useful in case of memory problems
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

props= {'envelopMethod'     'hilbert'    '!CHAR(hilbert)'
        'movAvgMethod'      'centered'   '!CHAR'
        'movAvgMsec'        100          'DOUBLE[1]'
        'movAvgOpts'        {}           'CELL'
        'channelwise'       false        'BOOL'};

if nargin==0,
  dat= props; return
end

if length(varargin)==1,
  opt= struct('appendix', varargin{1});
else
  opt= opt_proplistToStruct(varargin{:});
end

[opt, isdefault]= opt_setDefaults(opt, props);
opt_checkProplist(opt, props);

sz= size(dat.x);
switch(lower(opt.envelopMethod)),
 case 'hilbert',
  if opt.channelwise
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

if ~isempty(opt.movAvgOpts),
  dat= proc_movingAverage(dat, opt.movAvgMsec, opt.movAvgOpts{:});
elseif ~isempty(opt.movAvgMsec) && opt.movAvgMsec>0,
  dat= proc_movingAverage(dat, opt.movAvgMsec, opt.movAvgMethod);
end
