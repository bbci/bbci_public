function res = pyff(command, varargin)

% PYFF -  wrapper function used to initialize and communicate with Pyff
%         (http://bbci.de/pyff) from Matlab
%
%Usage:
% res = pyff(command, <OPT>)
%
%IN:
% 'command' -  command to be issued: 'startup', 'init', 
%              'setdir','set', 'get', 'refresh','play', 'stop','quit',
%              'saveSettings', 'loadSettings'
%
% res = pyff('startup',<OPT>): startup pyff in a separate console window.
% res contains the command string that is executed. For
% this command, OPT is a property/value list or struct of options with 
% the following (optional) fields/properties:
%  .Dir      - pyff source directory (default for win: D:\svn\pyff\src;
%              default for unix: ~/svn/pyff/src)
%  .Parport     - port number for parallel port. Default is dec2hex(IO_ADDR),
%              if IO_ADDR exists, otherwise [].
%  .A        - additional feedback directory (default [])
%  .Gui      - if 1, pyff gui is started along with the feedback controller (default 0)
%  .L        - loglevel (default 'debug')
%  .Bvplugin - if 1, the BrainVision Recorder plugin is started (win: default 1;
%              unix: default 0)
%
% pyff('init',feedback): load and initialize pyff feedback 
%  feedback  - strint containing the name of the feedback
%
% pyff('setdir',<OPT>): set directory and filename for EEG recording. 
%  .TodayDir - directory for saving EEG data (default TODAY_DIR)
%  .VpCode   - the code of the VP (Versuchsperson) (default VP_CODE)
%  .Basename  - the basename of the EEG file (default '')
% Special cases: If OPT=='' all entries are set to '', ensuring that no EEG is 
% recorded. If OPT is not given at all, all entries are set to default.
%
% pyff('set',OPT): set feedback variables after the feedback has been
% initialized. OPT is a property/value list or struct of with
% fields/properties referring to names and values of variables. The type of
% the variable (string, integer, or float) is automatically checked. 
% NOTE: Unlike Python, Matlab automatically turns integers into floats! 
% For example, var1 = 1.0 and var1 = 1 both yield a float. This should not be a problem 
% in most cases, but if you definitely need an integer, you should provide the 
% type along with the value, e.g. pyff('set','var1',int16(1)).
% Alternatively, you can use the 'setint' command (below).
%
% pyff('setint',OPT): use this command to set feedback variables
% explicitly to integers. If you do this, each provided variable is
% cast to an integer.
%
% res = pyff('get',...): get the value of feedback variables.
% Give a list of variables to be inspected. res is a cell array containing
% the respective values of the variables. [wishful thinking, I think it's
% not possible]
%
% pyff('play'): start playing currently initialized feedback
% pyff('play', 'Basename', BASENAME, <PARAM>): start acquisition in BV Recorder, then start playing
%    currently initialized feedback. PARAM can be 'impedances', 0 to avoid
%    impedance measurement.
% pyff('stop'):  stop current feedback
% pyff('quit'):  quit current feedback (and stop acquisition in BV
%    Recorder).
%
% pyff('loadSettings', FILENAME),
% pyff('saveSettings', FILENAME): load or save the parameters of the feedback
%   to FILENAME. The appendix '.json' is automatically appended.
%   If FILENAME does not contain file separators '\' or '/',
%   TODAY_DIR is prepended.
%
%
% General OPT:
% 'Os'       - operating system 'win' or 'unix' (usually you do not need to
%              set this since the script figures out your OS)
% 'ReplaceHtmlEntities' - replaces symbols like '<' in string to be set via
%                    XML by their according HTML (XML compatible) entities
%OUT:
% res        - final command as a string
%
% ISSUES: 
% *command 'getvariables' (aka 'refresh') does not make variables
% appear in the GUI

% Matthias Treder 2010

global IO_ADDR TODAY_DIR VP_CODE acquire_func general_port_fields
persistent ACQ_STARTED

props = {'Os',                    'win',            '!CHAR(win unix)';
         'ReplaceHtmlEntities',   1,                '!BOOL';
         'Parport',               IO_ADDR,               'DOUBLE[1]';
         'A',                     [],               'CHAR';
         'Gui',                   0,                'BOOL';
         'L',                     'debug',          'CHAR';
         'Bvplugin',              1,                '!BOOL';
         'TodayDir',              TODAY_DIR,        'CHAR';
         'VpCode',                VP_CODE,          'CHAR';
         'Basename',              '',               'CHAR';
         'OutputProtocol',        [],               'CHAR';
         'Host',                 'localhost',       'CHAR';
         'Port',                  12345,            'INT';

};

if nargin==0,
  dat= props; return
end

misc_checkType('command','CHAR(startup init set setint setdir play refresh stop quit loadSettings saveSettings)');

%% Case-dependent check of parameters
switch(command)

  case {'startup','stop','quit'}
    narginchk(1,1);
    opt=[];
  case 'init'
    narginchk(2,2);
    feedback = varargin{1};
    opt=[];
    misc_checkType('feedback','!CHAR');
    ACQ_STARTED= 0;
    
  case 'setdir'
    narginchk(2,inf);
    if nargin==2
      opt=[];
      opt.TodayDir = '';
      opt.VpCode = '';
    else
      opt = opt_proplistToStruct(varargin{:});
    end

  case {'set','setint'}
    vars = opt_proplistToStruct(varargin{:});
    opt = [];
    if isfield(vars,'ReplaceHtmlEntities')
      warning 'Found variable ''ReplaceHtmlEntities'', assuming its a Pyff parameter, not a variable'
      opt.ReplaceHtmlEntities = vars.ReplaceHtmlEntities;
      vars = rmfield(vars,'ReplaceHtmlEntities');
    end
    
  case 'play'
    narginchk(1,5);
    opt = opt_proplistToStruct(varargin{:});
    
  case {'saveSettings','loadSettings'}
    narginchk(2,2);
    opt=[];
    filename = varargin{1};
    misc_checkType('filename','!CHAR');
    settings_file= [filename '.json'];
    if ~any(ismember('/\', settings_file)),
      settings_file= [TODAY_DIR settings_file];
  %   % Avoid overwriting? - Maybe it is intended, so we don't.
  %    if strcmp(command,'saveSettings') && exists(settings_file, 'file'),
  %      new_str= datestr(now, 'yyyy-mm-dd_HH:MM:SS.FFF');
  %      settings_file= [settings_file, '_', now_str];
  %    end
    end
end

[opt,isdefault] = opt_setDefaults(opt, props);
opt_checkProplist(opt, props);

% Figure out os (unless it was set manually)
if isdefault.Os
  if isunix || ismac
    opt.Os = 'unix';
  else
    opt.Os = 'win';
  end
end

switch(opt.Os)
  case 'win'
    opt= set_defaults(opt, 'Dir','D:\svn\pyff\src');
  case 'unix'
    opt= set_defaults(opt, 'Dir','~/svn/pyff/src');
    opt = opt_overrideIfDefault(opt,isdefault,'Bvplugin',0);
end

if isempty(opt.TodayDir), 	opt.TodayDir = '';end
if isempty(opt.VpCode), opt.VpCode = '';end
               
%% Execute command
res = [];
switch(command)

  case 'startup',
    
    if strcmp(opt.Os,'win')
      % get system path
      curr_path = getenv('PATH');
      % also sets the path back to the normal system variable. Matlab adds a
      % reference to itself to the beginning of the system path which
      % breaks PyQT.QtCore (possibly also other imports that require dll)
      comstr = ['set PATH=' curr_path '& cmd /C "cd ' opt.Dir ' & python FeedbackController.py'];
      opt.A= strrep(opt.A, '/', filesep);
    elseif strcmp(opt.Os,'unix')
      comstr = ['xterm -e python ' opt.Dir  '/FeedbackController.py'];
%       opt.A= strrep(opt.A, '\', filesep); % probably unneccesary
    end
    
    if ~isempty(opt.Parport)
      comstr = [comstr ' --port=0x' num2str(opt.Parport)];
    end
    if ~isempty(opt.A)
      comstr = [comstr ' -a "' opt.A '"'];
    end
    if opt.Gui==0
      comstr = [comstr ' --nogui'];
    end
    if ~isempty(opt.L)
      comstr = [comstr ' -l ' opt.L];
    end
    if opt.Bvplugin
      comstr = [comstr ' -p brainvisionrecorderplugin'];
    end
    if ~isempty(opt.OutputProtocol)
      comstr = [comstr ' --protocol ' opt.OutputProtocol];
    end
    
    if strcmp(opt.Os,'win')
      comstr = [comstr '" &'];
    elseif strcmp(opt.Os,'unix')
      comstr = [comstr ' &'];
    end
    system(comstr);
    res = comstr;
    send_udp_xml('init', opt.Host, opt.Port);
    general_port_fields.feedback_receiver= 'pyff';
    
  case 'init'
    send_udp_xml('interaction-signal', 's:_feedback', feedback,'command','sendinit');
    
  case 'setdir'
    send_udp_xml('interaction-signal', 's:TODAY_DIR',opt.TodayDir, ...
      's:VP_CODE',opt.VpCode, 's:BASENAME',opt.Basename);
    
  case 'set'
    settings= {};
    fn= fieldnames(vars);
    for ii= 1:numel(fn)
      val = vars.(fn{ii});
      % Take value or (if it is a cell) the value of its first element
      if ischar(val) || (iscell(val) && ischar(val{1}))
        typ= 's:';
        if opt.ReplaceHtmlEntities
          val = ReplaceHtmlEntities(val);
        end
      elseif isinteger(val) || (iscell(val) && isinteger(val{1}))
        typ= 'i:';
      elseif islogical(val)
        typ= 'b:';
        if val
          val= 'True';
        else
          val= 'False';
        end
      else
        typ= '';
      end
      settings= cat(2, settings, {[typ fn{ii}], val});
    end
    send_udp_xml('interaction-signal', settings{:});
  
  case 'setint'
    settings= {};
    fn= fieldnames(vars);
    typ= 'i:';
    for ii= 1:numel(fn)
      settings= cat(2, settings, {[typ fn{ii}], vars.(fn{ii})});
    end
    send_udp_xml('interaction-signal', settings{:});

  case 'play'
    if isempty(varargin),
      ACQ_STARTED= 0;
    else
      ACQ_STARTED= 1;
      bvr_startrecording(varargin{2}, 'append_VP_CODE',1, varargin{3:end});
      pause(0.01);
    end
    send_udp_xml('interaction-signal', 'command', 'play'); 
    
  case 'stop'
    send_udp_xml('interaction-signal', 'command', 'stop'); 
    
  case 'quit'
    send_udp_xml('interaction-signal', 'command', 'quit'); 
    if strcmp(func2str(acquire_func), 'acquire_bv') && ACQ_STARTED,
        bvr_sendcommand('stoprecording');
        ACQ_STARTED= 0;
    end
     
  case 'saveSettings'
    send_udp_xml('interaction-signal', 'savevariables', settings_file);
    
  case 'loadSettings'
    send_udp_xml('interaction-signal', 'loadvariables', settings_file);
    
end
