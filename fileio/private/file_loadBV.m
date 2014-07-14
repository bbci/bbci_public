function [varargout] = file_loadBV(file, varargin)
% FILE_LOADBV - load EEG data which is stored in BrainVision format.
%                  Loading is performed using Matlab code only. FILE_READBV 
%                  should be preferred for performance reasons.
%
% Synopsis:
%   [CNT, MRK, HDR]= file_loadBV(FILE, 'Property1',Value1, ...)
%
% Arguments:
%   FILE: file name (no extension),
%         relative to EEG_RAW_DIR unless beginning with '/' (resp '\').
%         FILE may also contain the wildcard symbol '*'. In this case
%         make sure that the order of the files (printed to the terminal)
%         is appropriate.
%         FILE may also be a cell array of file names.
%
% Properties:
%   'CLab': Channels to load (labels or indices). Default all
%           (which can be explicitly specified by [])
%   'Fs': Sampling interval, must be an integer divisor of the
%         sampling interval of the raw data. fs may also be 'raw' which means 
%         sampling rate of raw signals. Default: 'raw'.
%   'Ival': Interval to read, [start end] in msec. It is not checked
%           whether the whole interval could be loaded, or the file is shorter.
%   'IvalSa': Same as 'ival' but [start end] in samples of the downsampled data.
%   'Start': Start [msec] reading.
%   'MaxLen': Maximum length [msec] to be read.
%   'Filt': Filter to be applied to raw data before subsampling.
%           opt.Filt must be a struct with fields 'b' and 'a' (as used for
%           the Matlab function filter).
%           Note that using opt.Filt may slow down loading considerably.
%   'SubsampleFcn': Function that is used for subsampling after filtering, 
%           specified as as string or a vector.
%           Default 'subsampleByMean'. Other 'subsampleByLag'
%           If you specify a vector it has to be the same size as lag.
%   'LinearDerivation' : for creating bipolar channels (see
%   procutil_biplist2projection for details)
%
% Remark: 
%   Properties 'Ival' and 'Start'+'MaxLen' are exclusive, i.e., you may only
%   specify one of them.
%
% Returns:
%   CNT: struct for contiuous signals
%        .x: EEG signals (time x channels)
%        .clab: channel labels
%        .fs: sampling interval
%        .scale: if this field is given, the real data are .x*.scale, 
%           and .x is int
%   MRK: struct of marker information
%   HDR: struct of header information
%
% TODO: The function so far can only read specific formats, e.g.,
%       multiplexed, INT_16, ... The function does not even check, whether
%       the file is in this format!
%
% See also: eegfile_*
%
%Hints:
% A low pass filter to get rid of the line noise can be designed as follows:
%  hdr= file_loadBVheader(file);
%  Wps= [40 49]/hdr.fs*2;
%  [n, Ws]= cheb2ord(Wps(1), Wps(2), 3, 50);
%  [filt.b, filt.a]= cheby2(n, 50, Ws);
% You can also use filtdemo to design your own filters.


% Author(s): blanker@cs.tu-berlin.de
% ported to public toolbox by sven.daehne@tu-berlin.de

global BTB

props= {'CLab'              ''      'CHAR|CELL{CHAR}'
        'Fs'                'raw'   'CHAR|DOUBLE'
        'Start'             0       'DOUBLE[1]'
        'MaxLen'            inf     'DOUBLE[1]'
        'Prec'              0       'DOUBLE[1]'
        'Ival'              []      'DOUBLE[2]'
        'IvalSa'            []      'DOUBLE[2]'
        'SubsampleFcn'      @proc_subsampleByMean  'FUNC'
        'Channelwise'       0       'BOOL'
        'Filt'              []      'STRUCT(a b)'
        'LinearDerivation'  []      'STRUCT'
        'TargetFormat'      'bbci'  'CHAR'
        'Verbose'           1       'BOOL'};

props_readBVmarkers= file_readBVmarkers;
props_readBVheader= file_readBVheader;
all_props= opt_catProps(props, props_readBVmarkers, props_readBVheader);

if nargin==0,
  varargout= {all_props};
  return
end

opt_orig= opt_proplistToStruct(varargin{:});
[opt, isdefault]= opt_setDefaults(opt_orig, props);
opt_checkProplist(opt, all_props);

misc_checkType(file, 'CHAR|CELL{CHAR}');


if ~isempty(opt.Ival),
  if ~isdefault.Start || ~isdefault.MaxLen,
    error('specify either ''Ival'' or ''Start''+''MaxLen'' but not both');
  end
  if ~isempty(opt.IvalSa),
    error('specify either ''Ival'' or ''IvalSa'' but not both');
  end
  opt.Start= opt.Ival(1);
  opt.MaxLen= diff(opt.Ival)+1;
end

% if isempty(opt.Filt) & ~isequal(opt.subsample_fcn, 'subsampleByLag'),
%   warning('When opt.Filt is not set subsampling is done by lagging.');
%   %% workaround: use opt.Filt= struct('b',1, 'a',1);
% end

%% prepare return arguments
varargout= cell(1, nargout);

if iscell(file),
  if opt.Start~=0 | opt.MaxLen~=inf,
    error('concatenation can (so far) only be performed in complete loading');
  end
  [varargout{:}]= fileutil_concatBV(file, varargin{:});
  return;
end

if file(1)==filesep | (~isunix & file(2)==':') 
  fullName= file;
else
  fullName= fullfile(BTB.RawDir, file);
end

if ischar(fullName) & ismember('*', fullName),
  dd= dir([fullName '.eeg']);
  if isempty(dd),
    error(sprintf('no files matching %s found', [fullName '.eeg']));
  end
  fc= cellfun(@(x)(x(1:end-4)), {dd.name}, 'UniformOutput',0);
  fullName= strcat(fileparts(fullName), '/', fc);
  if length(fc)>1,
    fprintf('concatenating files in the following order:\n');
    for k=1:length(fc)
        fprintf('%s\n', fullName{k});
    end
  end
  [varargout{:}]= file_loadBV(fullName, opt);
  return;
end

hdr= file_readBVheader(file);
cnt.clab= hdr.clab;
scale= hdr.scale;
raw_fs= hdr.fs;
endian= hdr.endian;

if isequal(opt.Fs, 'raw'),
  opt.Fs= raw_fs;
end
lag = raw_fs/opt.Fs;


if ~isempty(opt.LinearDerivation),
  rm_clab= cell_flaten({opt.LinearDerivation.rm_clab});
  rmidx= util_chanind(cnt.clab, rm_clab);
  cnt.clab(rmidx)= [];
  cnt.clab= cat(2, cnt.clab, rm_clab);
end

cnt.fs= opt.Fs;
nChans= length(cnt.clab);
if isempty(opt.CLab),
  chInd= 1:nChans;
else
  chInd= unique(util_chanind(cnt.clab, opt.CLab));
  cnt.clab= {cnt.clab{chInd}};
end
uChans= length(chInd);


if ~isempty(opt.Filt),
  opt_tmp= rmfield(opt_orig, 'Filt');     %% this is very unschön
  opt_tmp= setfield(opt_tmp, 'Fs','raw');
  opt_tmp= setfield(opt_tmp, 'SubsampleFcn', @proc_subsampleByLag); % ??
  opt_tmp= setfield(opt_tmp, 'Verbose',0);
  opt_tmp= setfield(opt_tmp, 'LinearDerivation',[]);
  tic;
  for cc= 1:uChans,
    if cc==1 && nargout>1,
      [cnt_sc, mrk]= file_loadBV(file, opt_tmp, 'Clab',cnt.clab{cc});
    else
      cnt_sc= file_loadBV(file, opt_tmp, 'Clab',cnt.clab{cc});
    end
    cnt_sc= proc_filt(cnt_sc, opt.Filt.b, opt.Filt.a);
    cnt_sc= opt.SubsampleFcn(cnt_sc, lag);
    if cc==1,
      cnt.x= zeros(size(cnt_sc.x,1), uChans);
      cnt.title= cnt_sc.title;
      cnt.file= cnt_sc.file;
    end
    cnt.x(:,cc)= cnt_sc.x;
    if opt.Verbose,
      util_printProgress(cc, uChans);
    end
  end
  if ~isempty(opt.LinearDerivation),
    ld= opt.LinearDerivation;
    for cc= 1:length(ld),
      ci= util_chanind(cnt.clab, ld(cc).chan);
      support= find(ld(cc).filter);
      s2= util_chanind(cnt.clab, ld(cc).clab(support));
      cnt.x(:,ci)= cnt.x(:,s2) * ld(cc).filter(support);
      cnt.clab{ci}= ld(cc).new_clab;
    end
    cnt= proc_selectChannels(cnt, 'not', rm_clab);
  end
  varargout{1}= cnt;
  if nargout>1
    varargout{2}= mrk;
  end
  return;
end

switch hdr.BinaryFormat
 case 'INT_16',
  cellSize= 2;
  if opt.Prec,
    prec= sprintf('%d*short=>short', nChans);
    cnt.scale= scale(chInd);
  else
    prec= sprintf('%d*short', nChans);
  end
  
 case 'DOUBLE',
  if opt.Prec,
    error('Refuse to convert double to INT16');
  end
  cellSize= 8;
  prec= sprintf('%d*double', nChans);
  
 case {'IEEE_FLOAT_32','FLOAT_32'},
  if opt.Prec,
    error('Refuse to convert double to FLOAT_32');
  end
  cellSize= 4;
  prec= sprintf('%d*float32', nChans);
  
 case {'IEEE_FLOAT_64','FLOAT_64'},
  if opt.Prec,
    error('Refuse to convert double to FLOAT_32');
  end
  cellSize= 8;
  prec= sprintf('%d*float64', nChans);
  
 otherwise
  error(sprintf('Precision %s not known.', hdr.BinaryFormat));
end

fid= fopen([fullName '.eeg'], 'r', endian);
if fid==-1, error(sprintf('%s.eeg not found', fullName)); end

fseek(fid, 0, 'eof');
fileLen= ftell(fid);
if ~isempty(opt.IvalSa),
  if ~isdefault.start | ~isdefault.maxlen,
    error('specify either <ival_sa> or <start/maxlen> but not both');
  end
  skip= opt.IvalSa(1)-1;
  nSamples= diff(opt.IvalSa)+1;
else
  skip= max(0, floor(opt.Start/1000*raw_fs));
  nSamples= opt.MaxLen/1000*raw_fs;
end
nSamples_left_in_file= floor(fileLen/cellSize/nChans) - skip;
nSamples= min(nSamples, nSamples_left_in_file);

if nSamples<0,
  warning('negative number of samples to read');
  [varargout{:}]= deal([]);
end

T= floor(nSamples/lag);
if uChans<nChans,
  opt.Channelwise= 1;
end

%% if lagging is needed, pick the sample in the middle
offset= cellSize * (skip + (ceil(lag/2)-1)) * nChans;

%% hack-pt.1 - fix 2GB problem of fread
if exist('verLessThan')~=2 | verLessThan('matlab','7'),
  zgb= 1024*1024*1024*2;
  if offset>=zgb & (opt.Channelwise | lag>1),
    postopos= cellSize * lag * nChans;
    overlen= offset - zgb + 1;
    nskips= ceil(overlen/postopos) + 1;  %% '+1' is to be on the save side
    newoffset= offset - nskips*postopos;
    offcut= nskips + 1;
    T= T + nskips;
    offset= newoffset;
  else
    offcut= 1;
  end
end

%% prepare return arguments
varargout= cell(1, nargout);

if ~opt.Channelwise,
  
  %% read all channels at once
  fseek(fid, offset, 'bof');
  cnt.x= fread(fid, [nChans T], prec, cellSize * (lag-1)*nChans);
  for ci= 1:uChans,
    cn= chInd(ci);    %% this loopy version is faster than matrix multiplic.
    if ~opt.Prec
      cnt.x(ci,:)= scale(cn)*cnt.x(ci,:);
    end
  end
  cnt.x= cnt.x';
else
  
  %% read data channelwise
  %% BB: Who wrote the opt.Prec stuff. That looks quite odd.
  if ~ischar(opt.Prec)&opt.Prec
    cnt.x= repmat(int16(0),[T,uChans]);
    for ci = 1:uChans,
      if opt.Verbose,
        fprintf('read channel %3i/%3i   \r', ci, uChans);
      end
      cn= chInd(ci);
      fseek(fid, offset+(cn-1)*cellSize, 'bof');
      cnt.x(:,ci)= [fread(fid, [1 T], '*short', cellSize * (lag*nChans-1))]';
    end
    cnt.scale= scale(chInd);
  else
    cnt.x= zeros(T, uChans);
    for ci= 1:uChans,
      if opt.Verbose,
        fprintf('read channel %3i/%3i   \r', ci, uChans);
      end
      cn= chInd(ci);
      fseek(fid, offset+(cn-1)*cellSize, 'bof');
      if ischar(opt.Prec)
        % Data precision: float32 or similar. 
        cnt.x(:,ci)= [scale(cn) * ...
            fread(fid, [1 T], opt.Prec, cellSize * (lag*nChans-1))]';
      else
        % Data precision: int16
        cnt.x(:,ci)= [scale(cn) * ...
            fread(fid, [1 T], 'short', cellSize * (lag*nChans-1))]';
      end
    end    
  end
  if opt.Verbose,
    fprintf('                      \r');
  end
end
fclose(fid);

%% hack-pt.2 - fix 2GB problem of fread
if exist('verLessThan')~=2 | verLessThan('matlab','7'),
  if offcut>1,
    cnt.x= cnt.x(offcut:end,:);
  end
end

cnt.title= file;
cnt.file= fullName;

if ~isempty(opt.LinearDerivation),
  ld= opt.LinearDerivation;
  for cc= 1:length(ld),
    ci= util_chanind(cnt.clab, ld(cc).chan);
    support= find(ld(cc).filter);
    s2= util_chanind(cnt.clab, ld(cc).clab(support));
    cnt.x(:,ci)= cnt.x(:,s2) * ld(cc).filter(support);
    cnt.clab{ci}= ld(cc).new_clab;
  end
  cnt= proc_selectChannels(cnt, 'not', rm_clab);
end

varargout{1}= cnt;
if nargout>1,
  mrk= file_readBVmarkers(file);
  varargout{2}= mrk;
end
if nargout>2,
  varargout{3}= hdr;
end
