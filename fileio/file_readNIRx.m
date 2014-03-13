function [varargout] = file_readNIRx(file, varargin)
% file_readNIRx - load NIRS data acquired by NIRx system into BTB format. By default, preprocessing 
% using the modified Beer-Lambert transform and the reduction of source-detector
% combinations is performed.
%
% Synopsis:
%   [CNT, MRK, MNT, HDR]= file_readNIRx(FILE, 'Property1',Value1, ...)
%
% Arguments:
%   FILE: file name (no extension), relative to BTB.RawDir unless the 
%         filename is an absolute path
%         FILE may also contain the wildcard symbol '*'. In this case
%         make sure that the order of the files (printed to the terminal)
%         is appropriate.
%         FILE may also be a cell array of file names.
%
% Properties:
%   'Path' : directory with raw NIRS data (default BTB.RawDir). 
%           If data is file contains an absolute path, Path is ignored.
%   'Restrict': restrict channels using nirs_restrictMontage (default 1)
%   'Source': labels of the sources. If not specified, numbers are used and
%            a warning is issued. The order of the labels has to
%            accord with the physical channels.
%   'Detector': labels of the detectors. If not specified, numbers are used and
%            a warning is issued. The order of the labels has to
%            accord with the physical channels.
%   'LBepsilon' : epsilon matrix used in Lambert-Beer transform (default
%                 value should be fine...)
%   'LB':   Whether or not to perform the Lambert-Beer transform (default 1)
%   'LBparam' : specify parameters (key/value pairs) to be transmitted to 
%            nirs_LB as cell array (eg {'opdist' 2}) %%JM: which parameters cn
%            be used?
%   'Filt': Filter to be applied to raw data *after* Lambert-Beer transform
%           (if applies).
%           opt.filt must be a struct with fields 'b' and 'a' (as used for
%           the Matlab function filter). %% which filter will be used?
%   'FiltType': Sets the type of filtering function used. 1 (default) uses
%           the causal 'proc_filt' function. 2 uses 'proc_filtfilt'.
%   'System': NIRS system used (default 'nirx')
%   'Extension' : extension for the data files for wavelengths 1 and 2. If
%           not set, the extension is determined automatically based on the
%           NIRS system. %%JM: ?
%
% Parameters to the nirs functions called can be passed to nirsfile_loadRaw 
% and are automatically transmitted.
%
% Remark: 
%   Raw data is in volt (returning photons converted to voltage) and should
%   be converted to absorption values (mmol/l) using the modified Beer-Lambert transform.
%   If you do not want this, set 'LB' to 0.
%   The two wavelengths (or oxy and deoxy if Beer-Lambert transformation was applied) are
%   stacked behind each other in the x-field as [wl1 wl2] or [oxy deoxy];
%  
%  
% NIRx file structure:
%   .hdr       : header file, contains also the markers in decimal form
%                with both sample-wise and second-wise timestamps
%   .evt       : markers in binary form
%   .wl1 .wl2  : data files for wavelengths 1 and 2, where wl1=short wavelength
%                and wl2=long wavelength
%
% Returns:
%   CNT: struct for continuous signals
%        .fs: sampling interval
%        .x : NIRS signals, either raw voltage counts for the two
%             wavelengths (if LB=0) or oxygenated haemoglobin signals and 
%             de-oxygenated haemoglobin signals. Format: time x (channels*2)
%        .source: source channels
%        .detector: detector channels
%        .clab: channel labels of [source x detector] channels. As a convention,
%               the resulting channel names consist of a concatenation
%               of source and detector, e.g. source at Pz and detector at Cz -> Pz-Cz.
%        .multiplexing: indicates whether only one source was
%        turned on each time ('single') or whether two sources ('dual')
%        were on simultaneously
%        .signal: indicating the signal type (here 'nirs')
%   MRK: struct of marker information
%   HDR: struct of header information
%
%
% See also: nirs_* nirsfile_*
%
% matthias.treder@tu-berlin.de 2011
% Markus Wenzel 2013 (adapted it to the new toolbox)
% Jan Mehnert 2013 (testing + adapting to file_readBV)
% Jan Mehnert February 2014 (ready for public BTB toolbox) (jan@mehnert.org)

% Attention, when the NIRS function names are changed: 
% The function calls file_readNIRxHeader and itself (file_readNIRx)

    
global BTB
props={ 'CLab'          ''              'CHAR|CELL{CHAR}'        
        'LB'            0               'BOOL'    
        'LBparam'       {}              'CELL'
        'Source'        []              'CHAR|CELL{CHAR}'
        'Detector'      []              'CHAR|CELL{CHAR}'     
        'Restrict'      1               'BOOL'
        'Fs'            'raw'           'CHAR|DOUBLE'
        'Filt'          []              'STRUCT(a b)'      
        'FiltType'      1               'DOUBLE'
        'System'        'nirx'          'CHAR'     
        'Extension'     []              'CHAR|CELL{CHAR}'
        'Verbose'       0               'BOOL'
        'RemoveOptodes' 0               'BOOL'
        'Dist'          5               'DOUBLE'
        'Connector'     ''             'CHAR'}; % E.g. _ or - between source and detector      
           
if nargin==0,
    varargout= {props};
    return
end

opt= opt_proplistToStruct(varargin{:});
[opt, isdefault]= opt_setDefaults(opt, props);

if ~ismember(opt.System,{'nirx'})
  error('Unknown NIRS system %s.',opt.System)
end

opt_checkProplist(opt, props);
misc_checkType(file, 'CHAR|CELL{CHAR}');

if ~iscell(file)
  file = {file};
end

% use BTB.RawDir as default dir
for filePos = 1:length(file)
  if fileutil_isAbsolutePath(file{filePos}),
    file{filePos}= file{filePos};
  else
      if isdir(fullfile(BTB.RawDir, file{filePos})) % in case only a directory containing the actual nirs files is set
          fileTemp=dir(fullfile(BTB.RawDir, file{filePos},'*.wl1'));
          if length(fileTemp)==1
              file{filePos}=fullfile(BTB.RawDir, file{filePos},fileTemp.name(1:end-4));
          else
              disp('The raw file directory conatins more than one NIRS data set.')
          end
      else
        file{filePos} = fullfile(BTB.RawDir, file{filePos});
      end
  end
end

% get all files specified with the file object
fileNamesTemp = {};
for filePos = 1:length(file)

  if ischar(file{filePos}) && ismember('*', file{filePos}),
    dd= dir([file{filePos} '.wl1']);
    if isempty(dd),
      error('\nFile not found: %s\n', file{filePos});
    end
    fc= cellfun(@(x)(x(1:end-4)), {dd.name}, 'UniformOutput',0);
    
    fileNamesTemp = cat(2,fileNamesTemp,strcat(fileparts(file{filePos}), '/', fc));
  else
    fileNamesTemp = cat(2,fileNamesTemp,{file{filePos}});
  end
end
file = fileNamesTemp;
if length(file)>1,
  if opt.Verbose,
    fprintf('concatenating files in the following order:\n');
    fprintf('%s\n', str_vec2str(file));
  end
end

% Define file extensions
if isdefault.Extension
  switch(opt.System)
    case 'nirx'
      opt.Extension = {'.wl1' '.wl2'};
  end
end

% Convert numeric clab to cell array of strings
if isnumeric(opt.Source)
  opt.Source = cellfun(@num2str, num2cell(opt.Source));  
end
if isnumeric(opt.Detector)
  opt.Detector = cellfun(@num2str, num2cell(opt.Detector));  
end

%% *** Process multiple files ***
%JM: not tested yet!!
% Has a wildcard -> search folder and convert to cell array of filenames
if ischar(file) && ismember('*', file)
  fp = fileparts(file);
  dd= dir([fullfile(opt.Path,file) opt.Extension{1}]);
  if isempty(dd)
    error('no files matching %s found', file);
  end
  file = cellfun(@(x)(x(1:end-4)), {dd.name}, 'UniformOutput',0);
  file = strcat(fp,filesep,file);
end

if iscell(file),
  % Traverse files
  if numel(file)>1
    hdr = file_readNIRxHeader(file);
    T= [];
    fprintf('concatenating files in the following order:\n');
    fprintf('%s\n', str_vec2str(file));

    for f = file
      [cnt, mrk,dum,mnt]= file_readNIRx(f{:}, varargin{:});
      % T = [T size(cnt.x,1)]; % Alte Toolbox sample-basiert
      T = [T size(cnt.x,1)*1000/cnt.fs];
      if strcmp(f{:},file{1})
        ccnt= cnt;
        cmrk= mrk;
      else
        if ~isequal(cnt.clab, ccnt.clab),
          error('source x detector channels are inconsistent across files'); 
        end
        if ~isequal(cnt.fs, ccnt.fs)
          error('inconsistent sampling rate'); 
        end
        ccnt.x= cat(1, ccnt.x, cnt.x);
        % mrk.pos= mrk.pos + sum(T(1:end-1)); % Alte Toolbox sample-basiert
        mrk.time= mrk.time + sum(T(1:end-1));
        
        cmrk= mrk_mergeMarkers(cmrk, mrk);
      end
    end

    ccnt.T= T;
    if numel(file)>1
      ccnt.title= [ccnt.title ' et al.'];
      ccnt.file= strcat(fileparts(ccnt.file), file);
    end
    cnt = ccnt;
    mrk = cmrk;
    return;
  else
    file = file{1};
  end
end

%% **** Read header ****
opt_tmp = struct_copyFields(opt, {'System','Verbose'});
hdr=file_readNIRxHeader(file, opt_tmp);
hdr.system = opt.System;

if opt.Verbose; fprintf('Source wavelengths: [%s] nm\n',num2str(hdr.wavelengths)); end

%% **** Read marker ****
if nargout>1
  opt_tmp = struct_copyFields(opt,{'System','Verbose'});
  mrk = file_readNIRxMarker(file, opt_tmp);
  mrk.fs = hdr.fs;
  if opt.Verbose; fprintf('Markers read, %d events found.\n',numel(mrk.desc)); end
end

%% **** Read NIRS data ****
cnt.fs= hdr.fs;
cnt.nSources = hdr.nSources;
cnt.nDetectors = hdr.nDetectors;

if strcmp(opt.System,'nirx')
  % Read wavelengths 1 and 2
  wl1 = readDataMatrix([file opt.Extension{1}]);
  wl2 = readDataMatrix([file opt.Extension{2}]);

  % Infer from number of columns whether multiplexing was single or dual
  % Source-detector format in single mode
  %   s1-d1,s1-d2,..s1-dN, s2-d1,s2-d2....s2-dN,....
  %   so column 4 is the light going from source 1 to detector 4
  % Source-detector format in dual mode
  % z1-d1,z1-d2,..z1-dN, z2-d1,z2-d2....z2-dN,...
  % where z is a combination of 2 sources. The source-pairs are coupled in
  % a fixed way. For 16 sources, the coupled sources are s1-s9, s2-s10, ...
  % s8-16. So in the raw data column 4 is the light going from s1 and s9 to
  % d4.
  nCol = size(wl1,2);
  if nCol==hdr.nSources * hdr.nDetectors
    cnt.multiplexing = 'single';
  elseif nCol==hdr.nSources * hdr.nDetectors/2
    cnt.multiplexing = 'dual';
    % Only half of data columns in dual mode (because two source were 'on'
    % each time), therefore simply concatenate the data
    wl1 = [wl1 wl1];
    wl2 = [wl2 wl2];
  else
    error 'Number of data columns does not match the number of channels'
  end
  hdr.multiplexing = cnt.multiplexing;
  if opt.Verbose
    fprintf(['Expecting %d channels (%d sources, %d detectors) and found '...
      '%d data columns; inferring that multiplexing is ''%s''.\n'], ...
      hdr.nSources*hdr.nDetectors,hdr.nSources,hdr.nDetectors,nCol,cnt.multiplexing)
    if strcmp(cnt.multiplexing,'dual')
      fprintf('Duplicating the %d data columns to assure %d channels.\n',nCol,hdr.nSources*hdr.nDetectors)
    end    
  end  
end

%% Stack wavelengths together in one field
cnt.x = [wl1 wl2];

%% **** Source and detector labels *****
if ~isfield(cnt,'source')
  sourceClab = opt.Source;
else
  sourceClab = cnt.source.clab;
end
if ~isfield(cnt,'detector')
  detectorClab = opt.Detector;
else
  detectorClab = cnt.detector.clab;
end


%% **** Montage ****
if nargout >= 3 && (isempty(sourceClab) || isempty(detectorClab))  
 % Hadi: made it >= instead of > because of the way calibrate.m calls
  mnt = struct();
  warning('Sources or detectors not found/specified. Making empty montage')
  %empty montage
  for i=1:cnt.nSources
      for j=1:cnt.nDetectors
        mnt.clab{(i-1)*cnt.nDetectors+j}=['s' num2str(i) 'd' num2str(j) 'highWL'];
        mnt.clab{(i-1)*cnt.nDetectors+j+cnt.nSources*cnt.nDetectors}=['s' num2str(i) 'd' num2str(j) 'lowWL'];        
      end
  end
  cnt.clab=mnt.clab;
elseif nargout >= 3 % Hadi: made it >= instead of > because of the way calibrate.m calls
  opt_tmp = struct_copyFields(opt, ...
                              {'~ClabPolicy', ...
                               '~Projection','~Connector'});
  mnt = mnt_getNIRSMontage(sourceClab,detectorClab,opt_tmp);
  cnt.clab=[strcat(mnt.clab,'highWL') strcat(mnt.clab,'lowWL')];
  
  if opt.Restrict %JM: does currently not work.
    opt_tmp = struct_copyFields(opt, {'Dist','RemoveOptodes'});
    allclab = mnt.clab;
    mnt = mnt_restrictNIRSMontage(mnt,opt_tmp); 
    tmp_clab=[strcat(mnt.clab,'highWL') strcat(mnt.clab,'lowWL')];
    cnt = proc_selectChannels(cnt,tmp_clab,{'ignore' '-'});
  end

end

cnt.wavelengths = hdr.wavelengths;
cnt.signal = 'NIRS (high wavelength, low wavelength)';


%% **** modified Beer-Lambert transform ****
if opt.LB
	cnt = proc_BeerLambert(cnt,opt.LBparam{:});
else
    cnt.YUnit = 'V';
end

%% **** Filter ****
if ~isempty(opt.Filt),
  switch(opt.FiltType)
    case 1
      cnt = proc_filt(cnt,opt.Filt.b, opt.Filt.a);
    case 2
      cnt = proc_filtfilt(cnt,opt.Filt.b, opt.Filt.a);
    otherwise
      error('Unknown filt type "%d".\n',opt.FiltType)
  end
end

%% *** Return ***
[t,subject,r]=fileparts(file);
cnt.title= subject;
cnt.file= file;

if nargout ==1, varargout={cnt};%this displays the possible properties if the function was called without a file.
elseif nargout ==2, varargout={cnt,mrk};
elseif nargout ==3, varargout={cnt,mrk,mnt};
elseif nargout >3, varargout={cnt,mrk,mnt,hdr};
end
%% Read data function using 'textscan' (faster than 'textread')
function dat = readDataMatrix(file)
  fid = fopen(file,'r');
  % Read first line and determine nr of columns
  l1 = fgetl(fid);
  nCol = numel(strfind(l1,' ')) + 1;
  % Read
  fseek(fid,0,'bof');
  dat = textscan(fid,repmat('%n',[1 nCol]));
  dat = [dat{:}];
  % Tschuess
  fclose(fid);
end

end