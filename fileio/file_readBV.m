function [varargout] = file_readBV(file, varargin)
% FILE_READBV - load EEG data which is stored in BrainVision format.
%                  C-functions are used for better performance. Use the
%                  slower FILE_LOADBV if this function does not work.
%
% Synopsis:
%   [CNT, MRK, HDR]= file_readBV(FILE, 'Property1',Value1, ...)
%
% Arguments:
%   FILE: file name (no extension),
%         relative to BTB.RawDir unless beginning with '/' (resp '\').
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
%   'SubsamplePolicy': Function that is used for subsampling after filtering, 
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
% See also: file_* procutil_biplist2projection
%
%Hints:
% A low pass filter to get rid of the line noise can be designed as follows:
%  hdr= file_readBVheader(file);
%  Wps= [40 49]/hdr.fs*2;
%  [n, Ws]= cheb2ord(Wps(1), Wps(2), 3, 50);
%  [filt.b, filt.a]= cheby2(n, 50, Ws);
% You can also use filtdemo to design your own filters.


% Benjamin Blankertz

%   2008/06/20/ - Max Sagebaum
%               - refactored file_loadBV to read the data with read_bv.c
%               - removed code fragments marked as obsolete
%               - you can now use the ival option when concatinating
%                 multiple eeg files
%   2008/06/17  - Max Sagebaum
%               - the iir filter was not properly send to read_bv
%   2010/09/09  - Max Sagebaum
%               - There was an bug in the check for the lag


%% check if the mex file is present
readBV_status = exist('read_bv','file');
if not(readBV_status == 3)
    warning('Could not detect mex files for read_bv! Using file_loadBV instead.')
    varargout= cell(1, nargout);
    [varargout{:}]= file_loadBV(file, varargin{:});
    return;
end


%% start file_readBV
global BTB

props= {'CLab'               ''       'CHAR|CELL{CHAR}'
        'Fs'                 'raw'    'CHAR|DOUBLE'
        'Start'              0        'DOUBLE[1]'
        'MaxLen'             inf      'DOUBLE[1]'
        'Prec'               0        'DOUBLE[1]'
        'Ival'               []       'DOUBLE[2]'
        'IvalSa'             []       'DOUBLE[2]'
        'SubsamplePolicy'    'mean'   'CHAR(mean lag)|DOUBLE'
        'Filt'               []       'STRUCT(a b)'
        'LinearDerivation'   []       'STRUCT'
        'TargetFormat'       'bbci'   'CHAR'
        'Verbose'            1        'BOOL'
       };

props_readBVmarkers= file_readBVmarkers;
props_readBVheader= file_readBVheader;
all_props= opt_catProps(props, props_readBVmarkers, props_readBVheader);

if nargin==0,
  varargout= {all_props};
  return
end

opt= opt_proplistToStruct(varargin{:});
[opt, isdefault]= opt_setDefaults(opt, props);
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

%% read the headers an prepare the clab

if ~iscell(file)
  file = {file};
end

fileNames = cell(1,length(file));
fileTitle = cell(1,length(file));
% use BTB.RawDir as default dir
for filePos = 1:length(file)
  if fileutil_isAbsolutePath(file{filePos}),
    fileNames{filePos}= file{filePos};
    [dmy, fileTitle{filePos}]= fileparts(file{filePos});
  else
    fileNames{filePos} = fullfile(BTB.RawDir, file{filePos});
    fileTitle{filePos}= file{filePos};
  end
end

% get all files specified with the file object
fileNamesTemp = {};
for filePos = 1:length(file)

  if ischar(fileNames{filePos}) && ismember('*', fileNames{filePos},'legacy'),
    dd= dir([fileNames{filePos} '.eeg']);
    if isempty(dd),
      error('\nFile not found: %s\n', fileNames{filePos});
    end
    fc= cellfun(@(x)(x(1:end-4)), {dd.name}, 'UniformOutput',0);
    
    fileNamesTemp = cat(2,fileNamesTemp,strcat(fileparts(fileNames{filePos}), '/', fc));
  else
    fileNamesTemp = cat(2,fileNamesTemp,{fileNames{filePos}});
  end
end
fileNames = fileNamesTemp;
if length(fileNames)>1,
  if opt.Verbose,
    fprintf('concatenating files in the following order:\n');
    fprintf('  %s\n', fileNames{:});
  end
end

% now we read all headers and make some consistent checks if neeeded
hdr = cell(1,length(fileNames));
opt_readBVheader= opt_substruct(opt, props_readBVheader(:,1));
for filePos = 1:length(fileNames)
  hdr{filePos} = file_readBVheader(fileNames{filePos}, opt_readBVheader);
  
  % set the clabs and the raw_fs if we are in the loop for the first time
  if(filePos == 1)
    cnt.clab= hdr{filePos}.clab;
    raw_fs= hdr{filePos}.fs;
  end
	
  if ~isequal(cnt.clab, hdr{filePos}.clab),
    warning(['inconsistent clab structure will be repaired ' ...
             'by using the intersection']); 
    cnt.clab = intersect(cnt.clab, hdr{filePos}.clab,'legacy');
  end
  if isequal(opt.Fs, 'raw')
    % if we want to read the raw data check if for each file the raw data
    % is the same
    if~isequal(raw_fs, hdr{filePos}.fs)
      error('inconsistent sampling rate');
    end
  else
    % if we have a specific fs check if for each file we have a positive
    % lag
    lag = hdr{filePos}.fs/opt.Fs;
    if lag~=round(lag) || lag<1,
      error('fs must be a positive integer divisor of every file''s fs');
    end
  end
end
clab_in_file= cnt.clab;

% select specified channels
if ~isempty(opt.CLab) && strcmp(opt.TargetFormat,'bbci'),
  cnt.clab= cnt.clab(util_chanind(cnt, opt.CLab));
end

% sort channels for memory efficient application of linear derivation:
% temporary channels are moved to the end
if ~isempty(opt.LinearDerivation),
  rm_clab= cell_flaten({opt.LinearDerivation.rm_clab});
  rmidx= util_chanind(cnt.clab, rm_clab);
  cnt.clab(rmidx)= [];
  cnt.clab= cat(2, cnt.clab, rm_clab);
end

%% prepare the output samples
firstFileToRead = 1;
firstFileSkip = 0;
lastFileToRead = length(fileNames);
lastFileLength = inf;


% check if we want to load the raw data
if isequal(opt.Fs, 'raw'),
  opt.Fs= raw_fs;
end
cnt.fs= opt.Fs;
cnt.title = str_vec2str(fileTitle);
cnt.file = str_vec2str(fileNames);

nChans= length(cnt.clab);

% get the skip and maxlen values for the data in samples for the new
% sampling rate
if ~isempty(opt.IvalSa),
  if ~isdefault.Start || ~isdefault.MaxLen,
    error('specify either <IvalSa> or <Start/MaxLen> but not both');
  end
  skip= opt.IvalSa(1)-1;
  maxlen = diff(opt.IvalSa)+1;
else
  skip= max(0, floor(opt.Start/1000*opt.Fs));
  maxlen = ceil(opt.MaxLen/1000*opt.Fs);
end

%get the number of samples for every file and check from which file we have
%to read
nSamples = 0;
dataSamples = 0;
dataSize = zeros(1,length(fileNames));
for filePos = 1:length(fileNames)
  % check if we can read the data with read_bv
  % currently only 16Bit Integers are supported
  switch hdr{filePos}.BinaryFormat
   case 'INT_16',
    cellSize= 2;
    readbv_binformat(filePos)=1;
   case 'INT_32',
    cellSize= 4;
    readbv_binformat(filePos)=2;
   case {'IEEE_FLOAT_32', 'FLOAT_32'},
    cellSize= 4;
    readbv_binformat(filePos)=3;
   case {'IEEE_FLOAT_64', 'FLOAT_64', 'DOUBLE'},
    cellSize= 8;
    readbv_binformat(filePos)=4;
   otherwise
    error('Precision %s not known.', hdr.BinaryFormat);
  end
  
  % open the file to get the size
  fid= fopen([fileNames{filePos} '.eeg'], 'r', hdr{filePos}.endian);
  if fid==-1, error('%s.eeg not found', fileNames{filePos}); end
  fseek(fid, 0, 'eof');
  fileLen= ftell(fid);
  fclose(fid);
  
  curChannels = length(hdr{filePos}.clab);
  curLag = hdr{filePos}.fs/opt.Fs;
  samples_in_file = floor(fileLen/(cellSize*curChannels));
  samples_after_subsample = floor(samples_in_file / curLag);
  dataSize(filePos) = samples_after_subsample;
  
  % set the new first file and the first data in this file
  if nSamples <= skip
    firstFileToRead = filePos;
    firstFileSkip = skip - nSamples;
    dataSamples = samples_after_subsample - firstFileSkip;
  else
    dataSamples = dataSamples + samples_after_subsample;
  end
  % advance to the end of the cur file
  nSamples = nSamples + samples_after_subsample;
  
  % if we reach the end set the last file and stop reading
  if nSamples >= (skip + maxlen)
    lastFileToRead = filePos;
    lastFileLength = samples_after_subsample - (nSamples - (skip + maxlen));
    dataSamples = dataSamples - (samples_after_subsample - lastFileLength);
     break;
  else
    % only if we have no maxlen
    lastFileLength = samples_after_subsample;
  end
  
end

%% reading the data
%create the data block for all samples
chosen_clab = cnt.clab;
cnt.x = zeros(dataSamples,nChans);
cnt.T = dataSize;

dataOffset = 0; % the offset for the current file
for filePos = firstFileToRead:lastFileToRead
  % get the channel id for this file
  chanids = util_chanind(clab_in_file,chosen_clab); % the -1 is for read_bv
  
  read_opt = struct('fs',cnt.fs, 'chanidx',chanids);

  if ~isempty(opt.Filt)
    read_opt.filt_b = opt.Filt.b;
    read_opt.filt_a = opt.Filt.a;
  end
  % set the subsample filter 
  lag = hdr{filePos}.fs/opt.Fs;
  switch opt.SubsamplePolicy,
    case 'mean',
      read_opt.filt_subsample = ones(1,lag)/lag;
    case 'lag',
      read_opt.filt_subsample = [zeros(1,lag-1) 1];
    otherwise,
      read_opt.filt_subsample = opt.SubsamplePolicy;
  end

  read_hdr = struct('fs',hdr{filePos}.fs, ...
                    'nChans',hdr{filePos}.NumberOfChannels, ...
                    'scale',hdr{filePos}.scale, ...
                    'endian',hdr{filePos}.endian, ...
                    'BinaryFormat',readbv_binformat(filePos));

  % get the position for the data in the whole data set
  if firstFileToRead == filePos
    firstX = 1;
    firstData = firstFileSkip + 1;
  else
    firstX = lastX + 1;
    firstData = 1;
  end

  if lastFileToRead == filePos
    lastX = nSamples;
    lastData = lastFileLength;
  else
    lastX = firstX + dataSize(filePos) - 1 - firstFileSkip;
    lastData = dataSize(filePos);
  end

  read_opt.data = cnt.x;
  read_opt.dataPos = [firstX lastX firstData lastData] - 1;

  % read the data, read_bv will set the data in cnt.x because of the
  % read_opt.data options
  read_bv([fileNames{filePos} '.eeg'], read_hdr, read_opt);
  cnt.yUnit= hdr{filePos}.unit;

  %% Markers
  if nargout>1,
    opt_mrk= opt_substruct(opt, props_readBVmarkers(:,1));
    curmrk= file_readBVmarkers(fileNames{filePos}, opt_mrk);
    curmrk.time= curmrk.time + dataOffset*1000/cnt.fs;
    % find markers in the loaded interval
    inival= find(curmrk.time > skip*1000/cnt.fs & ...
                 curmrk.time <= (skip+maxlen)*1000/cnt.fs);
    % add special case: don't loose t=0 markers
    % NO: markers with time=0 make problems!
    %if skip==0,
    %  idxzero= find(curmrk.time==0);
    %  inival= [idxzero, inival];
    %end
    curmrk= mrk_selectEvents(curmrk, inival);
    %let the markers start at zero
    curmrk.time= curmrk.time - skip*1000/cnt.fs;

    if firstFileToRead == filePos
      mrk = curmrk;
    else
      mrk = mrk_mergeMarkers(mrk, curmrk);
    end
    dataOffset = dataOffset + dataSize(filePos);
  end
end
clear read_opt;

if ~isempty(opt.LinearDerivation),
  ld= opt.LinearDerivation;
  for cc= 1:length(ld),
    ci= util_chanind(cnt.clab, ld(cc).chan);
    support= find(ld(cc).filter);
    s2= util_chanind(cnt.clab, ld(cc).clab(support));
    cnt.x(:,ci)= cnt.x(:,s2) * ld(cc).filter(support);
    cnt.clab{ci}= ld(cc).new_clab;
  end
  % delete temporary channels: TODO in a memory efficient way
  idx= util_chanind(cnt, rm_clab);
  cnt.x(:,idx)= [];
  cnt.clab(idx)= [];
end

varargout= cell(1, nargout);

varargout{1}= cnt;
if nargout > 1,
  varargout{2} = mrk;
end
if nargout>2,
  if(1 == length(hdr))
    varargout{3} = hdr{1};
  else
      varargout{3}= hdr;
  end
end

