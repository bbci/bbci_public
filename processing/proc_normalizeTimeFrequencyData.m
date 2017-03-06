function dat= proc_normalizeTimeFrequencyData(dat, ival, varargin)
%PROC_NORMALIZETIMEFREQUENCYDATA - substract a baseline from a epoched data structure
%
%Synopsis:
%dat= proc_normalizeTimeFrequencyData(dat, ival)
%   
%Arguments:
%      dat  - data structure of epoched time-frequency data
%      ival - baseline interval [start ms, end ms]
%      channelwise - 0 (default) to save memory
%
%Returns:
%     dat  - updated data structure
%
%Description
% baseline correction for time-frequency EEG data, for example after 
% proc_wavelets. For each epoch, the average EEG
% amplitude in the specified interval is substracted for every channel,
% every trial (or class), and frequency.
%
%Examples:
%  dat_spec = proc_wavelets(epo, 5:35); % complex wavelet transform
%  dat_spec.x = abs(dat_spec.x); % compute power
%  dat_spec = proc_normalizeTimeFrequencyData(dat_spec, [-1000, 0]);
%

% Sven Daehne


props= {'Pos'      'beginning_exact'  'CHAR'
        'Channelwise'   0       'BOOL'};

if nargin==0,
  dat = props; return
end

dat = misc_history(dat);
misc_checkType(dat, 'STRUCT(x clab)'); 
misc_checkType(ival,'DOUBLE[1-2]'); 

if length(varargin)==1,
  opt= struct('pos', varargin{1});
else
  opt= opt_proplistToStruct(varargin{:});
end
[opt, isdefault]= opt_setDefaults(opt, props);
opt_checkProplist(opt, props);

nC = size(dat.x,3);  
switch(lower(opt.Pos)),
    case 'beginning_exact', % [-150 0] = 15 samples not 16 (at fs= 100 Hz)
        %      len= round(diff(ival)/1000*dat.fs);
        %      Ti= procutil_getIvalIndices(ival, dat);
        %      Ti= Ti(1:len);
        len= round(diff(ival)/1000*dat.fs);
        Ti= procutil_getIvalIndices(ival, dat);
        Ti= Ti(end-len+1:end);
    otherwise,
        Ti= procutil_getIvalIndices(ival, dat);
end
dat.refIval= dat.t(Ti([1 end]));

%% perform normalization

if opt.Channelwise,
    for ic=1:nC,
        dat.x(:,:,ic,:) = normalizeTFD(dat.x(:,:,ic,:), Ti);
    end
else
    dat.x = normalizeTFD(dat.x, Ti);
end


function X = normalizeTFD(X, Ti)
% This function does the actual normalization
% TODO: add more options

B = repmat(mean(X(Ti,:,:,:)),[size(X,1) 1 1 1]); % power in baseline interval
X = (X - B) ./ B;
