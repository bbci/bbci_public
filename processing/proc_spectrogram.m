function dat = proc_spectrogram(dat, freq, varargin)
% PROC_SPECTROGRAM -  calculates the spectrogram using short-time Fourier
% transformation.
%
%Usage:
%   dat = proc_spectrogram(dat, freq, <OPT>)
%   dat = proc_spectrogram(dat, freq, Window, <OPT>)
%   dat = proc_spectrogram(dat, freq, Window, NOverlap,<OPT>)
% 
%Arguments:
% DAT          - data structure of continuous or epoched data
% FREQ         - desired frequency bins (eg 1:100)
% OPT - struct or property/value list of optional properties:
% 'Window' -   if a vector, divides the data  into segments of length equal 
%              to the length of WINDOW, and then windows each
%              segment with the vector specified in WINDOW.  If WINDOW is an integer,
%              the data is divided into segments of length equal to that integer value, and a
%              Hamming window of equal length is used.  If WINDOW is not specified, the
%              default is used. Default dat.fs/2 (ie a 500 ms window).
% 'NOverlap' - number of samples each segment of X overlaps. Must be an 
%              integer smaller than the window length. Default: 
%              window length -1 (so that a time x frequency 
%              representation is defined for each sample)
% 'CLab'     - specifies for which channels the spectrogram is calculated.
%              (default '*')
% 'Output'   - Determines if and how the FFT coefficients are processed.
%              'complex' preserves the complex output (with both phase and
%              amplitude information), 'amplitude' returns the absolute
%              value, 'power' the squared absolute value, 'db' log power, 
%              and 'phase' the phase in radians. Default 'complex'.
% 'DbScaled' -  
%Returns:
% DAT    -    updated data structure with a higher dimension.
%             For continuous data, the dimensions correspond to 
%             time x frequency x channels. For epoched data, time x
%             frequency x channels x epochs.
%             The coefficients are complex. You can obtain the amplitude by
%             abs(dat.x), power by abs(dat.x).^2, and phase by
%             phase(dat.x);
%
% Note: Requires signal processing toolbox.
%
% See also proc_wavelets, proc_spectrum

% Stefan Haufe, Berlin 2004, 2010

props = {'Window',              []                          'DOUBLE';
         'DbScaled'             1                           '!BOOL';
         'NOverlap'             []                          'DOUBLE[1]';
         'CLab',                '*'                         'CHAR|CELL{CHAR}|DOUBLE[-]';
         'Output'               'complex'                   '!CHAR(complex amplitude power db phase)';
         };

if nargin==0,
  dat= props; return
end

misc_checkType(dat,'!STRUCT(x fs)');
misc_checkType(freq,'!DOUBLE[-]');

% Parse other arguments
if nargin>2 && isnumeric(varargin{1})
  window = varargin{1};
  remidx = 1;
	if nargin>3 && isnumeric(varargin{2})
    noverlap = varargin{2};
    remidx =[remidx 2];
    varargin = {'Window' varargin{1} 'NOverlap' varargin{2:end}};
  else
    varargin = {'Window' varargin{:}};
  end
end

opt= opt_proplistToStruct(varargin{:});
[opt,isdefault] = opt_setDefaults(opt, props);
opt_checkProplist(opt, props);

[opt,isdefault] = opt_overrideIfDefault(opt,isdefault,'Window',floor(dat.fs/2));

% Determine length of fft window
if numel(opt.Window)==1, winlen = opt.Window;
else winlen =  numel(opt.Window);
end
[opt,isdefault] = opt_overrideIfDefault(opt,isdefault,'NOverlap',winlen-1);

dat = misc_history(dat);

%% Spectrogram
dat = proc_selectChannels(dat,opt.CLab);

% Strech out data matrix to single vector (spectrogram does not operate on
% matrices). Interleave zero padding to prevent smearing between
% successive channels/epochs.
sz =size(dat.x);
zero = zeros([winlen-1, sz(2:end)]);
dat.x = cat(1,dat.x,zero);
% if ndims(dat.x) == 2      % cnt
  % Append also zeros at beginning and end
  X = zeros(2*(winlen-1)+numel(dat.x),1);
  X(winlen:end-winlen+1) = dat.x(:);
% elseif ndims(dat.x)==3    % epoched
% end

[S,F,T] = spectrogram(X,opt.Window,opt.NOverlap,freq,dat.fs);
clear X

S = S(:,floor(winlen/2):end-ceil(winlen/2)); % cut off padded values at beginning and end

% Reshape vector to matrix
if ndims(dat.x) == 2      % cnt
  dat.x = reshape(S',[sz(1)+winlen-1  sz(2) numel(freq)]);
  dat.x = dat.x(1:end-(winlen-1),:,:);
  dat.x = permute(dat.x,[1 3 2]);

elseif ndims(dat.x)==3    % epoched
  dat.x = reshape(S',[sz(1)+winlen-1  sz(2:end) numel(freq)]);
  dat.x = dat.x(1:end-(winlen-1),:,:,:);
  dat.x = permute(dat.x,[1 4 2 3]);
  
end

% dat.t = (T-winlen/2/dat.fs)*1000 + dat.t(1);
dat.f = freq;
dat.zUnit = 'Hz';

switch(opt.Output)
  case 'complex'
    % do nothing
  case 'amplitude'
    dat.x = abs(dat.x);
    dat.yUnit= 'amplitude';
  case 'power'
    dat.x = abs(dat.x).^2;
    dat.yUnit= 'power';
  case 'db'
    dat.x = 10* log10( abs(dat.x).^2 );
    dat.yUnit= 'log power';
  case 'phase'
    dat.x = angle(dat.x);
    dat.yUnit= 'phase';
end


% DBSCALED implementation fehlt noch

% if opt.DbScaled,
%   for chIdx = 1: length(chan),
%     ch = chan(chIdx) ;
%     for evt = 1: nEvt,
%       [B,F,T] = spectrogram([mean(epo.x(1:min(end,opt.Window),ch,evt))*ones(opt.Window/2,1); epo.x(:,ch,evt);mean(epo.x(max(1,end-opt.Window):end,ch,evt))*ones(opt.Window/2-1,1)], opt.Window, opt.Noverlap, opt.Nfft, epo.fs);     
%       dat.x(:,:,chIdx, evt) = abs(B(bandIdx, :)).^2;
%     end ;
%     dat.x(:,:,chIdx, :) = 10*log10( dat.x(:,:,chIdx, :)+eps ) ;
%   end ;
%   dat.yUnit= 'dB';
% else
%   for ch = chan,
%     for evt = 1: nEvt,
%       [B,F,T] = spectrogram([zeros(opt.Window/2,1);epo.x(:,ch,evt);zeros(opt.Window/2-1,1)], opt.Window, opt.Noverlap, opt.Nfft, epo.fs);      
%       dat.x(:,:,chIdx, evt) = abs(B(bandIdx, :)).^2;
%     end ;
%   end ;
%   dat.yUnit= 'power';
% end

