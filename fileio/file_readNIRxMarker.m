function mrk = file_readNIRxMarker(mrkName, varargin)
% file_readNIRxMarker - Read marker in NIRS format from single marker file.
%
% Synopsis:
%   [MRK, FS]= file_readNIRxMarker(MRKNAME,<OPT>)
%
% Arguments:
%   MRKNAME: name of marker file (no extension),
%            relative to BTB.RawDir unless beginning with '/'
%
% Properties:
%   'System': NIRS system used (default 'nirx')
%   'Prefix': string prepended to each marker string (default 'S '; e.g.
%             makes a marker "1" become "S 1")
%   'Path' : directory with raw NIRS data (default BTB.RawDir). 
%           If data is file contains an absolute path, path is ignored.

% Returns:
%   MRK: struct array of markers with fields desc (marker descriptor=number
%   from 0 to 15) and time (milliseconds relative to recording onset).
%
% Description:
%   Read all marker information from a Nirx generic data format file.
%   The sampling interval is read from the corresponding head file.
%
% Note: Based on eegfile_readBVmarkers.
% See also: nirs_* nirsfile_*
%
% matthias.treder@tu-berlin.de 2011
% Markus Wenzel 2013 (adapted it to the new toolbox)
% Jan Mehnert February 2014 (ready for pubic BTB toolbox) (jan@mehnert.org)

global BTB
props={ 'Path'           BTB.RawDir   'CHAR'
        'System'         'nirx'       'CHAR'    
        'Prefix'         'S'          'CHAR'
        'Verbose'        0            'BOOL'
        'MarkerFormat'   'numeric'    'CHAR(string numeric)'};
if nargin==0,
    mrk= props; return
end

opt= opt_proplistToStruct(varargin{:});
[opt, isdefault]= opt_setDefaults(opt, props);

% Clear opt.Path if mrkName contains absolute path (= starts with '/')
if fileutil_isAbsolutePath(mrkName),
  opt.Path=[];
  isdefault.Path=0;
end

opt_checkProplist(opt, props);
misc_checkType(mrkName, 'CHAR');%|CELL{CHAR}'); % single marker file


%% Scan marker file
fullName= fullfile(opt.Path,mrkName);
mrk = struct();

if strcmp(opt.System,'nirx')
  % Structure of file: (col 1) Timestamp (col 2-9) 8 bits signifying the
  % marker (caution! lowest bit is left [not right], need to flip bits before converting to decimal)
  fid = fopen([fullName '.evt'],'r');
  s= textscan(fid,'%d %s','delimiter','\n');
  pos = s{1}';
  % Remove \t's, flip bits and convert to decimal
  descno = cellfun(@(x)(bin2dec(fliplr(strrep(x,sprintf('\t'),'')))), s{2})';
  desc = str_cprintf([opt.Prefix '%3d'], descno);

  % get sampling frequency
  hdr=file_readNIRxHeader(fullName);
  mrk.time= pos*1000/hdr.fs;
  
  mrk.event.desc = desc';
end
mrk.time = double(mrk.time);

% New. Avoids errors in mrk_defineClasses. Adapted from file_readBVmarkers.
if strcmp(opt.MarkerFormat, 'numeric'),
  [toe,idx]= bbciutil_markerMappingSposRneg(mrk.event.desc);
  mrk.event.desc= zeros(size(mrk.event.desc));
  mrk.event.desc(idx)= toe;
end


