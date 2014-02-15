function [Mrk, fs]= file_readBVmarkers(mrkName, varargin)
% FILE_READBVMARKERS - Read Markers in BrainVision Format
%
% Synopsis:
%   MRK= file_readBVmarkers(MRKNAME, <OPT>)
%
% Arguments:
%   MRKNAME - CHAR: name of marker file (no extension),
%            relative to BTB.RawDir unless beginning with '/'
%   OPT - Struct or property/value list of optional properties:
%     'MarkerFormat': CHAR (default 'string'): specifies the format of the
%                     field MRK.event.desc:
%                          'string' : e.g. 'R  1', 'S123'
%                          'numeric': e.g.    -1 ,   123
%
% Returns:
%   MRK: struct array of markers with fields
%        time, event.desc, event.type, event.length, event.clab
%        which are defined in the BrainVision generic data format,
%        see the comment lines in any .vmrk marker file.
%
% Description:
%   Read all marker information from a BrainVision generic data format file.
%   The sampling interval is read from the corresponding head file.
%
% See also: file_*

% Benjamin Blankertz


global BTB

props= {'MarkerFormat'   'numeric'   'CHAR(string numeric)'};

if nargin==0,
  Mrk= props; return
end

opt= opt_proplistToStruct(varargin{:});
opt= opt_setDefaults(opt, props);
opt_checkProplist(opt, props);

misc_checkType(mrkName, 'CHAR');

if fileutil_isAbsolutePath(mrkName),
  fullName= mrkName;
else
  fullName= fullfile(BTB.RawDir, mrkName);
end


s= textread([fullName '.vmrk'],'%s','delimiter','\n');
skip= strmatch('[Marker Infos]', s, 'exact')+1;
if skip<=length(s)
  while s{skip}(1)==';',
    skip= skip+1;
  end
end 
opt_read= {'delimiter',',', 'headerlines',skip-1};

[mrkno, M_type, M_desc, pos, M_length, M_chan, M_clock]= ...
    textread([fullName '.vmrk'], 'Mk%u=%s%s%u%u%u%s', opt_read{:});

keyword= 'SamplingInterval';
s= textread([fullName '.vhdr'],'%s','delimiter','\n');
ii= strmatch([keyword '='], s);
fs= 1000000/sscanf(s{ii}, [keyword '=%f']);

Mrk.time= pos'*1000/fs;
% Round time to micro seconds
% Mrk.time= round(Mrk.time*1000)/1000;

Mrk.event.desc= M_desc;
Mrk.event.type= M_type;
Mrk.event.length= M_length;
Mrk.event.chan= M_chan;
Mrk.event.clock= M_clock;

% extract class definitions from desc
Mrk.className= unique(Mrk.event.desc)';
Mrk.y= zeros(length(Mrk.className), length(Mrk.event.desc));
for cc= 1:length(Mrk.className),
  idx= strmatch(Mrk.className{cc}, Mrk.event.desc, 'exact');
  Mrk.y(cc,idx)= 1;
end
% Let's avoid empty class names and replace them by 'n/d' (not defined).
% Alternatively, we could take the corresponding Mrk.event.type.
if isempty(Mrk.className{1}),
  Mrk.className{1}= 'n/d';
end

if strcmp(opt.MarkerFormat, 'numeric'),
  [toe,idx]= bbciutil_markerMappingSposRneg(Mrk.event.desc);
  Mrk.event.desc= zeros(size(Mrk.event.desc));
  Mrk.event.desc(idx)= toe;
end
