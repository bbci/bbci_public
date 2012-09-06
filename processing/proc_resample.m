function [dat, mrk] = proc_resample(dat, target_fs, varargin)
%PROC_RESAMPLE - resample the EEG data to a target sampling frequency
%
%Synposis:
% [dat, mrk] = proc_resample(dat, target_fs, <mrk, N>)
%
%Arguments:
%     dat - Structure with fields x and fs. This fields
%     will be overwritten
%     target_fs - the target sampling frequency
%
%     optional (given with keywords or as opt.xxx):
%     mrk - Structure with field time. It will be updated.
%     N - remove the first and last N samples from the resampled data to
%     avoid edge effects (default is 0)
%
%Returns:
%     dat: updated data structure
%     mrk: updated marker structure
%
%Description:
% Resamples the field dat.x such that is has the desired sampling frequency.
% dat.t and mrk (if given) will be updated as well.

% Sven Daehne, 06-2011


props= {'N'     0     '!INT[1]'
        'mrk'   []    'STRUCT'};

if nargin==0,
  dat= props; return
end

misc_checkType(dat, 'STRUCT(x fs)'); 
dat = misc_history(dat);

opt= opt_proplistToStruct(varargin{:});
[opt, isdefault]= opt_setDefaults(opt, props);
opt_checkProplist(opt, props);

N = opt.N;                  % # samples
Nt = N/target_fs*1000;      % corresponding time in ms
mrk = opt.mrk;

p = round(target_fs*1000);
q = round(dat.fs*1000);

if ndims(dat.x)==3
  nTrials = size(dat.x,3);
  for n= 1:nTrials,
    X(:,:,n) = resample(dat.x(:,:,n), p, q);
  end
else
  X = resample(dat.x, p, q);
end
dat.x = X;
dat.fs = target_fs;
n_samples = size(dat.x,1);
if isfield(dat, 't'),
  t = linspace(dat.t(1), dat.t(end), n_samples);
  dat.t = t; % time in ms
end

% remove the first and the last N samples to avoid edge effects
dat.x = dat.x((N+1):end-N, :, :);
if isfield(dat, 't')
    dat.t = dat.t((N+1):end-N);
end

% Adjust marker if necessary
if N>0 && ~isempty(mrk)
    mrk.time = mrk.time-Nt;
    % Remove markers that refer to data that was cut-off the beginning or
    % end
    rem_idx = [find(mrk.time<=0) find(mrk.time>length(dat.x)/dat.fs*1000)];
    mrk = mrk_selectEvents(mrk,'not',rem_idx);
end
