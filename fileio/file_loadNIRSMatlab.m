function varargout= file_loadNIRSMatlab(file, varargin)
% file_loadNIRSMatlab - Load NIRS data structure from Matlab file
%
% Synopsis:
%   [DAT, MRK, MNT,NFO...]= file_loadNIRSMatlab(FILE, VARS)
%   [DAT, MRK, MNT,...]= file_loadNIRSMatlab(FILE, 'Property1', Value1, ...)
%
% Arguments:
%   FILE: name of data file
%   VARS: Variables (cell array of strings) which are to be loaded,
%         default {'dat','mrk','mnt'}. The names 'dat', 'cnt' and 'epo'
%         are treated equally.
%
% Returns:
%   Variables in the order specified in VARS. Default [DAT,MRK,MNT,NFO] or
%   less, depending on the number of output arguments.
%
% Properties:
%   'Path': Path to save the file. Default is the global variable BTB.MatDir 
%           unless FILE is an absolute path.
%   'Vars': cell array of variables to-be-loaded (default 
%           {'dat','mrk','mnt','nfo'}. The order corresponds with the order
%           of the output arguments.
%   'Clab': Channel labels (cell array of strings) for loading a subset of
%           all channels. Default 'ALL' means all available channels.
%           In case OPT.clab is not 'ALL' the electrode montage 'mnt' is 
%           adapted automatically.
%   'Signal' : which signal should be contained in the cnt.x-field: 'oxy',
%             'deoxy' (default), 'oxy-deoxy' (or 'both').
%   'Verbose' : 0 (default) or 1
%
% Note: Based on eegfile_loadMatlab.
%
% matthias.treder@tu-berlin.de 2011
% Markus Wenzel 2013 (adapted it to the new toolbox)
% Jan Mehnert February 2014 (ready for public BTB toolbox) (jan@mehnert.org)

global BTB                                   
datnames = {'dat','cnt','epo'};
default_vars= {'dat','mrk','mnt','nfo'};

props= {'Path'      BTB.MatDir      'CHAR'
        'Clab'      'ALL'           'CHAR|CELL{CHAR}'
        'Vars'      default_vars(1:min(4,nargout))  'CELL{CHAR}'
        'Signal'   'deoxy'          'CHAR'
       };   
      
if nargin==0,
    mrk= props; return
end


if numel(varargin)==1 && iscell(varargin{1})  
  opt= opt_proplistToStruct('Vars', varargin{1});
else
    opt= opt_proplistToStruct(varargin{:});    
end

[opt, isdefault]= opt_setDefaults(opt, props);

% Clear opt.Path if file contains absolute path (= starts with '/')
if ~iscell(file) && fileutil_isAbsolutePath(file),
    opt.Path=[]; isdefault.Path=0;
end

if ~iscell(opt.Vars), opt.Vars = {opt.Vars}; end
opt_checkProplist(opt, props);
misc_checkType(file, 'CHAR|CELL{CHAR}');


if nargout~=length(opt.Vars)
  warning('number of output arguments does not match with requested vars');
end

fullname= fullfile(opt.Path,file);
iData= find(ismember(opt.Vars, datnames));

%% Load non-data variables
load_vars= setdiff(opt.Vars,opt.Vars{iData});
S= load(fullname, load_vars{:});

%% Check whether all requested variables have been loaded.
missing= setdiff(load_vars, fieldnames(S));
if ~isempty(missing)
  error(['Variables not found: ' sprintf('%s ',missing{:})]);
end

%% Adapt electrode montage, if only a subset of channels is requested
if isfield(S, 'mnt') && ~isequal(opt.Clab, 'ALL'),
  S.mnt= mnt_adaptMontage(S.mnt, opt.Clab);
end

%% Load data
if ~isempty(iData)
  names = whos('-file',fullname);  % Check name of dat file
  names = {names.name};
  name = intersect(datnames,names);
  if isempty(name)
    error(['Neither of the data variables found: ' sprintf('%s ',datnames{:})])
  elseif numel(name)>1
    warning(sprintf('Found multiple data variables (%s), taking ''%s''\n',sprintf('''%s'' ',name{:}),name{1}))
    name = name{1};
  else
    name = name{:};
  end
  dat = load(fullname,name);
  dat = dat.(name);
  switch(opt.Signal)
    case 'oxy'
        dat.x = dat.x(:,1:end/2);
        dat.clab = dat.clab(:,1:end/2);
        dat.clab = strrep(dat.clab, 'highWL', '');
        dat.clab = strrep(dat.clab, 'oxy', '');
    case 'deoxy' 
        dat.x = dat.x(:,end/2+1:end);
        dat.clab = dat.clab(:,end/2+1:end);
        dat.clab = strrep(dat.clab, 'lowWL', '');
        dat.clab = strrep(dat.clab, 'deoxy', '');
    case {'oxy-deoxy' 'both'}
        % nix
    otherwise error('Unknown signal %s',opt.Signal)
  end
end

dat.xInfo = opt.Signal;

%% Output arguments
for vv= 1:nargout
  if ismember(vv, iData),
    varargout(vv)= {dat};
  else
    varargout(vv)= {getfield(S, opt.Vars{vv})};
  end
end
