function [varargout]= file_loadMatlab(file, varargin)
% EEGFILE_LOADMATLAB - Load EEG data structure from Matlab file
%
% Synopsis:
%   [DAT, MRK, MNT]= file_loadMatlab(FILE, VARS)
%   [DAT, MRK, MNT]= file_loadMatlab(FILE, <OPT>)
%
% Arguments:
%   FILE:   CHAR|CELL{CHAR}   name of data file or list of files
%   VARS:   CELL    Variables (cell array of strings) which are to be loaded,
%                   default {'dat','mrk','mnt'}. The names 'dat', 'cnt' and 'epo'
%                   are treated equally.
%
% Returns:
%   DAT: structure of continuous or epoched signals
%   MRK: marker structure
%   MNT: electrode montage structure
%
% Properties:
%   'Vars': see arguments
%   'Clab': Channel labels (cell array of strings) for loading a subset of
%           all channels. Default '*' means all available channels.
%           See function 'chanind' for valid formats. In case OPT.Clab is
%           not '*' the electrode montage 'mnt' is adapted automatically.
%   'Ival': Request only a subsegment to be read [msec]. This is especially
%           useful to load only parts of very large files.
%           Use [start_ms inf] to specify only the beginning.
%           Default [] meaning the whole time interval.
%   'Fs': Sampling rate (must be a positive integer divisor of the fs
%         the data is saved in). Default [] meaning original fs.
%   'Path': In case FILE does not include an absolute path, OPT.Path
%           is prepended to FILE. Default BTB.MatDir (global BTB variable).
%
% Remark:
%   Properties 'ival' and 'fs' are particularly useful when data is saved
%   channelwise. Then cutting out the interval and subsampling is done
%   channelwise while reading the data, so a lot of memory is saved
%   compared to loading the whole data set first and then cutting out
%   the segment resp. subsample.
%
% Example:
%   file= 'Gabriel_03_05_21/selfpaced2sGabriel';
%   [cnt,mrk,mnt]= file_loadMatlab(file);
%   %% or just to load variables 'mrk' and 'mnt':
%   [mrk,mnt]= file_loadMatlab(file, {'mrk','mnt'});
%   %% or to load only some central channels
%   [cnt, mnt]= file_loadMatlab(file, 'clab','C5-6', 'vars',{'cnt','mnt'});
%
% See also: file_loadBV file_saveMatlab

% Author(s): Benjamin Blankertz, Feb 2005

%% Warning: if the opt.Ival option is used for *epoched* data,
%%   the field epo.t is not set correctly.

global BTB


if length(varargin)==1 && (iscell(varargin{1}) || ischar(varargin{1}))
  if iscell(varargin{1})
     vars = varargin{1};
  else
     vars = {varargin{1}};
  end
  varargin(1)=[];
else
  vars= {'dat','mrk','mnt','nfo'};
end

if nargout > length(vars),
  error('more output arguments than requested variables');
end

props = {'Path',            BTB.MatDir       'CHAR';
         'Vars',            vars(1:nargout)  'CELL{CHAR}|CHAR';
         'CLab'             '*'              'CHAR|CELL{CHAR}';
         'Ival'             []               'DOUBLE[2]';
         'Fs'               []               'DOUBLE[1]';
         };

misc_checkType(file,'!CHAR|!CELL{CHAR}');
opt= opt_proplistToStruct(varargin{:});
[opt, isdefault]= opt_setDefaults(opt, props);
opt_checkProplist(opt, props);

if ~iscell(opt.Vars)
  opt.Vars= {opt.Vars};
end

if iscell(file),
  varargout= cell(1, length(opt.Vars));
  [varargout{:}]= fileutil_concatMatlab(file, opt);
  return;
end

fullname= fullfile(opt.Path, file);
if fileutil_isAbsolutePath(file),
  if ~isdefault.Path,
    warning('opt.Path is ignored, since file is given with absolute path');
  end
  opt.Path= '';
  fullname = file;
end


% keyboard

if ismember('*', file),
  [filepath, filename]= fileparts(fullname);
  dd= dir(filepath);
  resr= regexp({dd.name}, filename);
  cc= ~cellfun(@isempty,resr);
  if sum(cc)==0,
    error(sprintf('no match for pattern ''%s'' in folder ''%s''', ...
                  filename, filepath));
  end
  iMatch= find(cc);
  fullname= strcat(filepath, '/', {dd(iMatch).name});
  varargout= cell(1, length(opt.Vars));
  [varargout{:}]= fileutil_concatMatlab(fullname, opt);
  return;  
end

iData= find(ismember(opt.Vars, {'dat','cnt','epo'},'legacy'));

%% Load variables directly, except for data structure
load_vars= opt.Vars;
load_vars(iData)= [];

%% Load non-data variables
S= load(fullname, load_vars{:});

%% Check whether all requested variables have been loaded.
missing= setdiff(load_vars, fieldnames(S),'legacy');
if ~isempty(missing),
  error(['Variables not found: ' sprintf('%s ',missing{:})]);
end

%% Adapt electrode montage, if only a subset of channels is requested
if isfield(S, 'mnt')
  S.mnt= mnt_adaptMontage(S.mnt, opt.CLab);
end

if ~isempty(opt.Fs),
  load(fullname, 'nfo');
  lag= nfo.fs/opt.Fs;
  if lag~=round(lag) || lag<1,
    error('fs must be a positive integer divisor of the file''s fs');
  end
else
  lag= 1;
end

if ~isempty(iData),
  wstat= warning('off');
  load(fullname, 'dat');
  warning(wstat);
  if ~exist('dat','var'),  %% old data file
    load(fullname, 'cnt');
    if ~exist('cnt','var'),
      error('neither variable <dat> nor <cnt> found.');
    end
    dat= cnt;
  end
  dat.file= fullname;
  if isfield(dat, 'x'),
    %% Data structure containing all channels was saved.
    if isequal(opt.CLab, 'ALL'),
      chind= 1:size(dat.x,2);
    else
      chind= util_chanind(dat, opt.CLab);
      dat= proc_selectChannels(dat, opt.CLab);
    end
    dat.x= double(dat.x);
    if isfield(dat, 'resolution'),
      for ci= 1:length(chind),
        dat.x(:,ci,:)= dat.x(:,ci,:) * dat.resolution(chind(ci));
      end
    end
    if ~isempty(opt.Ival),
      dat= proc_selectIval(dat, opt.Ival);      
      dat.ival= opt.Ival;
    end
    if ~isempty(opt.Fs),
      dat= proc_subsampleByLag(dat, lag);
    end
  else
    %% Data has been saved channelwise.
    load(fullname, 'nfo');
    orig_clab= dat.clab;
    chind= util_chanind(orig_clab, opt.CLab);
    dat.clab= orig_clab(chind);
    if ~isempty(opt.Fs),
      lag= nfo.fs/opt.Fs;
      if lag~=round(lag) || lag<1,
        error('fs must be a positive integer divisor of the file''s fs');
      end
      dat.fs= dat.fs/lag;
      if isfield(dat, 'T'),
        dat.T= dat.T./lag;
      end
    else
      lag= 1;
    end
    if ~isempty(opt.Ival),
      dat.ival= opt.Ival;
      if isinf(opt.Ival(2))
          opt.Ival(2) = sum(dat.T)/dat.fs*1000;  % Set to maximum
      end
      iv= procutil_getIvalIndices(opt.Ival, nfo);
      iOut= find(iv<1 | iv>nfo.T);
      if ~isempty(iOut),
        warning('requested interval too large: truncating');
        iv(iOut)= [];
      end
      if lag~=1,
        iv= iv(ceil(lag/2):lag:end);
      end
      T= length(iv);
      ivalstr= '(iv)';
    elseif lag>1,
      T= floor(nfo.T/lag);
      ival_start= ceil(lag/2);
      ivalstr= sprintf('(%d:%d:%d)', ival_start, lag, ival_start+lag*(T-1));
    else
      T= nfo.T;
      ivalstr= '';
    end
    dat.x= zeros(T, length(chind), nfo.nEpochs);
    for ci= 1:length(chind),
      varname= ['ch' int2str(chind(ci))];
      load(fullname, varname);
      dat.x(:,ci,:)= double(eval([varname ivalstr]));
      if isfield(dat, 'resolution'),
        dat.x(:,ci,:)= dat.x(:,ci,:) * dat.resolution(chind(ci));
      end
      clear(varname);
    end
    if isfield(dat, 'resolution'),
      dat= rmfield(dat, 'resolution');
    end
  end
end

%% convert markers if old
if isfield(S,'mrk')
  if isfield(S.mrk,'pos')
      S.mrk = convert_markers(S.mrk);
  end
end

%% cut back mrk structure to the requested interval
if isfield(S,'mrk') && ~isempty(opt.Ival),
  inival= find(S.mrk.time>=opt.Ival(1) & S.mrk.time<=opt.Ival(2));
  S.mrk= mrk_selectEvents(S.mrk, inival);
  S.mrk.time = S.mrk.time - opt.Ival(1);
  S.mrk.ival= opt.Ival;
end

if ~isempty(opt.Fs), % do resampling in nfo
  S.nfo.fs = opt.Fs;
  S.nfo.T = nfo.T./lag;
end
for vv= 1:nargout,
  if ismember(vv, iData,'legacy'),
    varargout(vv)= {dat};
  else
    varargout(vv)= {getfield(S, opt.Vars{vv})};
  end
end
