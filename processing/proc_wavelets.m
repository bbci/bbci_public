function [dat,info]  = proc_wavelets(dat,freq,varargin)
% PROC_WAVELETS -  calculates the continuous wavelet transform for a
% specified range of scales. (Wavelet coefficients are obtained in Fourier
% space.
%
%Usage:
% dat = proc_wavelets(dat,<OPT>)
% dat = proc_wavelets(dat,freq,<OPT>)
%
%Arguments:
% DAT      -  data structure of continuous or epoched data
% FREQ     -  Fourier center frequencies of the wavelets (eg [1:100] Hz)
% OPT - struct or property/value list of optional properties:
% 'Mother' -  mother wavelet (default 'morlet'). Morlet is currently the
%             only implemented wavelet.
% 'w0'    -   unitless frequency constant defining the trade-off between
%             frequency resolution and time resolution. For Morlet
%             wavelets, it sets the width of the Gaussian window. (default 7)
%
%Returns:
% DAT    -    updated data structure with a higher dimension.
%             For continuous data, the dimensions correspond to 
%             time x frequency x channels. For epoched data, time x
%             frequency x channels x epochs.
% INFO   -    struct with the following fields:
% .fun       - wavelet functions (in Fourier domain)
% .length    - length of each wavelet in time samples
% .freq      - wavelet center frequencies
%
% Interpretation of the data: Wavelet coefficients can be complex, that is,
% consisting of a real part real(dat.x) and an imaginary part imag(dat.x). 
% Use abs(dat.x) and angle(dat.x) to get amplitude and phase spectra.
%
%Memory consumption: The dimensionality of the data is increased by one dimension,
% leading to a substantial increase in memory consumption. Selection
% of a subset of electrodes and trials may alleviate memory issues.
%
% See also PROC_SPECTROGRAM.

% Author: Matthias Treder (2010,2012)

props = {'Mother',             'morlet',            '!CHAR(morlet)';
         'w0',                 7,                   '!DOUBLE[1]'
         };

if nargin==0,
  dat= props; return
end

dat = misc_history(dat);
opt= opt_proplistToStruct(varargin{:});
[opt,isdefault] = opt_setDefaults(opt, props);
opt_checkProplist(opt, props);
misc_checkType(dat,'STRUCT(x fs)');
misc_checkType(dat.fs,'!DOUBLE[1]','dat.fs');
misc_checkType(dat.x,'DOUBLE[2- 1]|DOUBLE[2- 2-]|DOUBLE[- - -]','dat.x');  % accept about everything except row vectors
misc_checkType(freq,'DOUBLE[-]');

%% Prepare
clear pi

dt = 1/dat.fs;  % time resolution (determined by sampling frequency)

% % Prepare output stuff
info = struct();
info.fun = cell(1,numel(freq));
% info.frequency = freq;

% Needed for Fourier version
N = size(dat.x,1);      % Length of signal = length of FFT
siz = size(dat.x);
siz(1)=[];
if siz(end)==1; siz(end)=[]; end  % cope with vectors with singleton dimensions
w = [(2*pi*[1:floor(N/2)])/(N*dt)  -(2*pi*[floor(N/2)+1:N])/(N*dt)]; % Angular frequency for k<= N/2

F = fft(dat.x);
dat.x = zeros([N length(freq) siz]);

%% Define mother wavelet, normalization factor, and fourier period
% [ and normalization ..]
switch(opt.Mother)
  case 'morlet'
    e = exp(1);
    psi0 = 'pi^(-1/4) * (w>0) .* e.^(-((s*w-opt.w0).^2)/2)'; % Mother wavelet
    scf = '(opt.w0+sqrt(2+opt.w0^2))/(4*pi*f)'; % How to obtain scale as a function of Fourier frequency  
end

%% Define scales corresponding to the desired frequencies
scales = zeros(1,numel(freq));    % Wavelet scales
for ii=1:numel(freq)
  f=freq(ii);
  scales(ii) = eval(scf);
end

%% Wavelet transform
for ii=1:numel(scales)
    % Traverse scales and create wavelet functions
    s = scales(ii);
    norm = sqrt( (2*pi*s)/dt );  % Normalization of wavelet in Fourier space
    info.fun{ii} = norm * eval(psi0)';
%     if nargout==2, info.fun{ii} = fun; end
    
    dat.x(:,ii,:,:) = ifft(F .* repmat(info.fun{ii},[1 siz]));
end

dat.f= freq;