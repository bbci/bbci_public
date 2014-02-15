function hdr= file_readNIRxHeader(hdrName, varargin)

% Funktion ruft sich selbst auf! file_readNIRxHeader. Falls sie umbenannt
% wird muss man dies im Code entsprechend ändern!
% Die Funktion wird auch von nirsfile_readMarker verwendet. Auch dort muss
% man sie entsprechend umbenennen!


% NIRSFILE_READHEADER - Read NIRS Header from single or multiple header
%                       files.
%
% Synopsis:
%   HDR= nirs_readHeader(HDRNAME, 'Property1',Value1, ...)
%
% Arguments:
%   HDRNAME: name of header file (no extension),
%            relative to BTB.RawDir unless beginning with '/'.
%            HDRNAME may also contain '*' as wildcard or be a cell
%            array of strings
%
% Properties:
%   'Path' : directory with raw NIRS data (default BTB.RawDir). 
%            If data is file contains an absolute path, path is ignored.
%   'System': NIRS system used (default 'nirx')
%   'HeaderExt': file extension for header (by default determined
%                automatically based on the system, eg., '.hdr')
%
% Returns:
%   HDR: header structure:
%   .fs    - sampling frequency
%
%   nirx fields:
%   .Gains - gain setting of photon counter (smth like impedances in EEG).
%            Possible values 1-10, the higher the better, 6-8 is realistic.
%            Since always two sources are 'on' at the same time, there's
%            gain settings for only half of the sources.
%   .nSources/.nDetectors - number of sources and detectors
%   .SDkey - coupling between source (1st col) and detector (2nd col). The
%            order corresponds to the order of source-detector channels in
%            the x (data) field.
%
% Based on eegfile_readBVheader
% See also: nirsfile_* nirs_*

% matthias.treder@tu-berlin.de 2011
% Markus Wenzel 2013 (adapted it to the new toolbox)
% Jan Mehnert February 2014 (ready for public BTB toolbox) (jan@mehnert.org)


global BTB
props={'HeaderExt'  []          'CHAR|CELL{CHAR}'
        'System'    'nirx'      'CHAR'
        'Path'      BTB.RawDir 'CHAR'
        'Verbose'   0           'BOOL'};
    
if nargin==0,
    hdr= props; return
end

opt= opt_proplistToStruct(varargin{:});
[opt, isdefault]= opt_setDefaults(opt, props);

% Clear opt.Path if hdrName contains absolute path (= starts with '/')
if ~iscell(hdrName) && fileutil_isAbsolutePath(hdrName),
    opt.Path=[]; isdefault.Path=0;
end

opt_checkProplist(opt, props);
misc_checkType(hdrName, 'CHAR|CELL{CHAR}');


if ~any(ismember(opt.System,{'nirx'}))
    error('Unknown NIRS system %s.',opt.System)
end

% Determine extension for header file
if isdefault.HeaderExt
    switch(opt.System)
        case 'nirx'
            opt.HeaderExt = '.hdr';
    end
end
%% Get file(list) and process multiple files
if ischar(hdrName) && ismember('*', hdrName),
    tmpName= fileutil_getFilelist(hdrName, 'ext',opt.HeaderExt);
    if isempty(tmpName), error('%s.%s not found', hdrName,opt.HeaderExt); end
    hdrName= tmpName;
end

% Traverse multiple files
if iscell(hdrName),
    hdr_array= struct([]);
    for ii= 1:length(hdrName),
        hdr= file_readNIRxHeader(hdrName{ii},varargin{:});
        hdr_array= struct_sloppycat(hdr_array, hdr, 'matchsize',1);
    end
    hdr = struct();
    % Create single struct
    fn = fieldnames(hdr_array);
    for ff={fn{:}}
        dum = {hdr_array.(ff{:})};
        if ischar(dum{1}) && numel(unique(dum))==1
            % ** STRING **
            % If all strings are the same, take single string
            dum = unique(dum);
            hdr.(ff{:}) = [dum{:}];
        elseif isscalar(dum{1}) && numel(unique([dum{:}]))==1
            % ** NUMBER **
            % If all numers are the same, take single number
            hdr.(ff{:}) = unique([dum{:}]);
        elseif isvector(dum{1}) && isnumeric(dum{1}) && ...
                isequal(dum{:})
            % ** VECTOR **
            % If all number vectors are the same, take one
            hdr.(ff{:}) = dum{1};
        elseif ~isvector(dum{1}) && isnumeric(dum{1}) && ...
                isequal(dum{:})
            % ** MATRIX **
            % If all number matrices are the same, take one
            hdr.(ff{:}) = dum{1};
        else
            hdr.(ff{:}) = dum;
        end
    end
    
    return;
end

%% Open and process header
fullName = fullfile(opt.Path,[hdrName opt.HeaderExt]);
fid= fopen(fullName, 'r');
if fid==-1, error(sprintf('%s not found', fullName)); end
[dmy, filename]= fileparts(fullName);

if strcmp(opt.System,'nirx')
    % ****************
    % *** nirx ***
    % ****************
    % General Info
    cs = '[GeneralInfo]'; % current section
    getEntry(fid, cs);
    hdr.fileName = getEntry(fid, 'FileName=', 0, filename,cs);
    hdr.date = getEntry(fid, 'Date=', 0,[],cs);
    hdr.time = getEntry(fid, 'Time=', 0,[],cs);
    
    % Imaging Parameters
    cs = '[ImagingParameters]'; % current section
    getEntry(fid, cs);
    hdr.nSources = getEntry(fid, 'Sources=',1,[],cs);
    hdr.nDetectors = getEntry(fid, 'Detectors=',1,[],cs);
    hdr.nWavelengths = getEntry(fid, 'Wavelengths=',1,[],cs);
    hdr.trigIns = getEntry(fid, 'TrigIns=',0,[],cs);
    hdr.trigOuts = getEntry(fid, 'TrigOuts=',0,[],cs);
    hdr.fs= getEntry(fid, 'SamplingRate=',0,[],cs);
    
    % Paradigm
    cs = '[Paradigm]';
    getEntry(fid, cs);
    hdr.stimulusType = getEntry(fid, 'StimulusType=', 0, [],cs);
    
    % GainSettings
    cs = '[GainSettings]';
    getEntry(fid, cs);
    % Gain = Sowas wie Impedanzen
    str = getEntry(fid, 'Gains=', 0);
    % Read gain matrix
    % if strcmp(str,'#')
    if any(strfind(str,'#')) % works also for "#
        str= deblank(fgets(fid));
        hdr.gains = [];
        % while ~strcmp(str,'#')
        while ~any(strfind(str,'#')) % works also for "#
            hdr.gains = [hdr.gains; str2num(str)];
            str= deblank(fgets(fid));
        end
    end
    
    % DataStructure
    cs = '[DataStructure]';
    getEntry(fid, cs);
    % Save SDKey string as numeric array
    % eval(['hdr.SDkey=[' getEntry(fid, 'S-D-Key=',1,[],cs) '];']);
    str = getEntry(fid, 'S-D-Mask=', 0);
    % Read gain matrix
    % if strcmp(str,'#')
    if any(strfind(str,'#')) % works also for "#
        str= deblank(fgets(fid));
        hdr.SDmask = [];
        %while ~strcmp(str,'#')
        while ~any(strfind(str,'#')) % works also for "#
            hdr.SDmask = [hdr.SDmask; str2num(str)];
            str= deblank(fgets(fid));
        end
    end
    % Wavelength is fixed but not coded in the header
    hdr.wavelengths = [760 850];
end



%% Fertig

fclose(fid);



%% Help functions
function [entry, str]= getEntry(fid, keyword, mandatory, default_value,rewind)
% 'mandatory' - an error is issued if keyword not found
% 'rewind'    - rewind file position back to some pointer (given as string)

if ~exist('mandatory','var'), mandatory=1; end
if ~exist('default_value','var'), default_value=[]; end
if ~exist('rewind','var'), rewind=[]; end
entry= 1;

if keyword(1)=='[',
    fseek(fid, 0, 'bof');
end
ok= 0;
while ~ok && ~feof(fid),
    str= fgets(fid);
    ok= strncmp(keyword, str, length(keyword));
end
if ~ok,
    if mandatory,
        error(sprintf('keyword <%s> not found', keyword));
    else
        entry= default_value;
        return;
    end
end
if keyword(end)=='=',
    entry= deblank(str(length(keyword)+1:end));
end

% Convert to double if number
if ~isnan(str2double(entry))
    entry = str2double(entry);
end

if ~isempty(rewind)
    getEntry(fid, rewind);
end
