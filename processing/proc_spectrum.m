function dat= proc_spectrum(dat, band, varargin)
%PROC_SPECTRUM -  calculate the power spectrum
%
%dat= proc_spectrum(dat, band, <win/N, step>)
%dat= proc_spectrum(dat, band, <opts>)
%
%
% IN   dat  - data structure of continuous or epoched data
%      band - frequency band
%      win  - window for FFT
%      N    - window width for FFT -> square window, default dat.fs
%      step - step for window (= # of overlapping samples), default N/2
%      opt  - struct of options:
%       .win       - window for FFT, default ones(dat.fs, 1)
%       .step      - step for window, default N/2
%       .db_scaled - boolean, if true values are db scaled (10*log10),
%                    default true
%
% OUT  dat  - updated data structure


if ~isempty(varargin) && isnumeric(varargin{1}),
    %% arguments given as <win/N, step>
    opt.Win= varargin{1};
    if length(varargin)>=2 && isnumeric(varargin{2}),
        opt.Step= varargin{2};
    end
else
    %% arguments given as <opt>
    opt= opt_proplistToStruct(varargin{:});
end
props= {'Win'     dat.fs   'DOUBLE'
        'Step'    []       'INT'
        'Scaling' 'db'     'CHAR(db power normalized unnormalized complex)'
       };
[opt, isdefault]= opt_setDefaults(opt, props, 1);
misc_checkType(dat, 'STRUCT(x fs)')
misc_checkType(band, 'DOUBLE[1 2]');

[T, nChans, nEvents]= size(dat.x);
if length(opt.Win)==1,
    if opt.Win>T,
        if ~isdefault.Win,
            warning(['Requested window length longer than signal: ' ...
                'shortening window, no zero-padding!']);
        end
        opt.Win= T;
    end
    opt.Win=ones(opt.Win,1);
end
N= length(opt.Win);
normWin  = norm(opt.Win) ;
if isdefault.Step, opt.Step= floor(N/2); end
if ~exist('band','var') || isempty(band), band= [0 dat.fs/2]; end

[bInd, Freq]= procutil_getBandIndices(band, dat.fs, N);
XX= zeros(N, nChans*nEvents);
nWindows= 1 + max(0, floor((T-N)/opt.Step));
iv= 1:min(N, T);
Win= repmat(opt.Win(:), [1 nChans*nEvents]);

switch(lower(opt.Scaling)),
    case 'db',
        for iw= 1:nWindows,
            XX= XX + abs(fft(dat.x(iv,:).*Win, N)).^2;
            iv= iv + opt.Step;
        end
        XX = XX/(nWindows*normWin^2);
        dat.x= reshape( 10*log10( XX(bInd,:)+eps ), [length(bInd), nChans, nEvents]);
        dat.yUnit= 'dB';
    case 'power',
        for iw= 1:nWindows,
            XX= XX + abs(fft(dat.x(iv,:).*Win, N).^2);
            iv= iv + opt.Step;
        end
        dat.x= reshape(XX(bInd,:)/(nWindows*normWin^2), [length(bInd), nChans, nEvents]);
        dat.yUnit= 'power';
    case 'unnormalized',
        for iw= 1:nWindows,
            XX= XX + abs(fft(dat.x(iv,:).*Win, N).^2);
            iv= iv + opt.Step;
        end
        dat.x= reshape(XX(bInd,:)/nWindows, [length(bInd), nChans, nEvents]);
        dat.yUnit= 'power';
    case 'normalized',
        for iw= 1:nWindows,
            XX= XX + abs(fft(dat.x(iv,:).*Win, N));
            iv= iv + opt.Step;
        end
        XX= XX*2/N;
        dat.x= reshape(XX(bInd,:)/nWindows, [length(bInd), nChans, nEvents]);
    case 'complex',
        for iw= 1:nWindows,
            XX= XX + fft(dat.x(iv,:).*Win, N);
            iv= iv + opt.Step;
        end
        XX = XX/(nWindows*normWin^2);
        dat.x= reshape( XX(bInd,:), [length(bInd), nChans, nEvents]);
        dat.yUnit= 'complex';
    otherwise,
        error('unknown choice for property *scaling*');
end

dat.t= Freq;
dat.xUnit= 'Hz';
