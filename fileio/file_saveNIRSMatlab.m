function file_saveNIRSMatlab(file, dat, mrk, mnt, varargin)
% file_saveNIRSMatlab - Save NIRS data structures in Matlab format
%
% Synopsis:
%   file_saveNIRSMatlab(FILE, DAT, MRK, MNT, 'Property1', Value1, ...)
%
% Arguments:
%   FILE: name of data file
%   DAT: structure of continuous or epoched signals
%   MRK: marker structure
%   MNT: electrode montage structure
%
% Properties:
%   'Path': Path to save the file. Default is the global variable EEG_MAT_DIR
%           unless FILE is an absolute path.
%   'Vars': Additional variables that should be stored. 'opt.Vars' must be a
%           cell array with a variable name / variable value structure, e.g.,
%           {'hdr',hdr, 'blah',blah} when blub and blah are the variables
%           to be stored.
%   'Fs_orig': store information about the original sampling rate
%
% See also: nirsfile_*  nirs_*
% Note: Based on eegfile_saveMatlab
%
% matthias.treder@tu-berlin.de 2011
% Markus Wenzel 2013 (adapted it to the new toolbox)
% Jan Mehnert February 2014 (ready for public BTB toolbox) (jan@mehnert.org)


global BTB                                              
props={ 'Path'          BTB.MatDir     'CHAR'
        'Fs_orig'       []              'DOUBLE'
        'Vars'          {}              'CELL'};   
      
if nargin==0,
    mrk= props; return
end

opt= opt_proplistToStruct(varargin{:});
[opt, isdefault]= opt_setDefaults(opt, props);

% Clear opt.Path if file contains absolute path (= starts with '/')
if ~iscell(file) && fileutil_isAbsolutePath(file),
    opt.Path=[]; isdefault.Path=0;
end

if ~iscell(opt.Vars), opt.Vars = {opt.Vars}; end
opt_checkProplist(opt, props);
misc_checkType(file, 'CHAR');
misc_checkType(dat, 'STRUCT');
misc_checkType(mrk, 'STRUCT');
misc_checkType(mnt, 'STRUCT');
 
fullname= fullfile(opt.Path,file);
dat.file= fullname;

%% Gather some summary information into structure 'nfo'.
nfo= struct_copyFields(dat, {'fs', 'clab','~source','~detector'});


if isfield(dat,'x')
  nfo.T= size(dat.x,1)*1000/dat.fs; % new toolbox time-based
end
if isfield(dat,'x') && ndims(dat.x)>2
  nfo.nEpochs= size(dat.x,3);
else
  nfo.nEpochs = 1;
end
nfo.length= nfo.T * nfo.nEpochs; % New toolbox: Length in ms; % Old toolbox: / dat.fs; % Length in seconds

nfo.file= fullname;
% if isfield(mrk, 'pos'), % old toolbox was sample-based
%   nfo.nEvents= length(mrk.pos);
if isfield(mrk, 'time'),
  nfo.nEvents= length(mrk.time);
else
  nfo.nEvents= 0;
end
if isfield(mrk, 'y'),
  nfo.nClasses= size(mrk.y,1);
else
  nfo.nClasses= 0;
end
if isfield(mrk, 'className'),
  nfo.className= mrk.className;
else
  nfo.className= {};
end
if ~isempty(opt.Fs_orig),
  nfo.fs_orig= opt.Fs_orig;
end

%% Create directory if necessary
[filepath, filename]= fileparts(fullname);
if ~exist(filepath, 'dir'),
  [parentdir, newdir]=fileparts(filepath);
  [status,msg]= mkdir(parentdir, newdir);
  if status~=1,
    error(msg);
  end
  if isunix,
    unix(sprintf('chmod a-rwx,ug+rwx %s', filepath));
  end
end

save(fullname, 'dat', 'mrk', 'mnt', 'nfo');

%% Save additional variables, as requested.
if ~isempty(opt.Vars)
  for vv= 1:length(opt.Vars)/2,
    eval([opt.Vars{2*vv-1} '= opt.Vars{2*vv};']);
  end
  save(fullname, '-APPEND', opt.Vars{1:2:end});
end
