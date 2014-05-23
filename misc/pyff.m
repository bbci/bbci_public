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
%  .Parport     - port number for parallel port. Default is dec2hex(BTB.Acq.IoAddr),
%              if BTB.Acq.IoAddr exists, otherwise [].
%  .A        - additional feedback directory (default [])
%  .Gui      - if 1, pyff gui is started along with the feedback controller (default 0)
%  .L        - loglevel (default 'debug')
%
% pyff('init',feedback): load and initialize pyff feedback 
%  feedback  - strint containing the name of the feedback
%
% pyff('setdir',<OPT>): set directory and filename for EEG recording. 
%  .TodayDir - directory for saving EEG data (default BTB.Tp.Dir)
%  .VpCode   - the code of the VP (Versuchsperson) (default BTB.Tp.Code)
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
% pyff('saveSettings', FILENAME): load or save the parameters of the feedback
%   to FILENAME. The appendix '.json' is automatically appended.
%   If FILENAME does not contain file separators '\' or '/',
%   BTB.Tp.Dir is prepended.
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


global BTB
%% TODO: get rid of these (change bvr_* functions to more general ones)
global acquire_func general_port_fields
persistent ACQ_STARTED

props = {'Os',                    'win',                  '!CHAR(win unix)';
         'PyffDir'                BTB.PyffDir             'CHAR';
         'ReplaceHtmlEntities',   1,                      '!BOOL';
         'Parport',               dec2hex(BTB.Acq.IoAddr),'CHAR';
         'A',                     [],                     'CHAR';
         'Gui',                   0,                      'BOOL';
         'L',                     'debug',                'CHAR';
         'TodayDir',              BTB.Tp.Dir,             'CHAR';
         'VpCode',                BTB.Tp.Code,            'CHAR';
         'Basename',              '',                     'CHAR';
         'OutputProtocol',        [],                     'CHAR';
         'Host',                 'localhost',             'CHAR';
         'Port',                  12345,                  'INT';
         'Impedances'             1                       'BOOL';

};

if nargin==0,
  dat= props; return
end

misc_checkType(command,'CHAR(startup init set setint setdir play refresh stop quit saveSettings loadSettings)');

%% Case-dependent check of parameters
switch(command)

  case {'stop','quit'}
    nargchk(1,1,nargin);
    opt=[];
  case 'startup'
    opt = opt_proplistToStruct(varargin{:});

  case 'init'
    nargchk(2,2,nargin);
    feedback = varargin{1};
    opt=[];
    misc_checkType(feedback,'!CHAR');
    ACQ_STARTED= 0;
    
  case 'setdir'
    nargchk(2,inf,nargin);
    if nargin==2
      opt=[];
      opt.TodayDir = '';
      opt.VpCode = '';
    else
      opt = opt_proplistToStruct(varargin{:});
    end

  case {'set','setint'}
    if nargin==2 && isstruct(varargin{1})
      vars= varargin{1};
    else
      vars = opt_proplistToStruct(varargin{:});
    end
    opt = [];
    if isfield(vars,'ReplaceHtmlEntities')
      warning 'Found variable ''ReplaceHtmlEntities'', assuming its a Pyff parameter, not a variable'
      opt.ReplaceHtmlEntities = vars.ReplaceHtmlEntities;
      vars = rmfield(vars,'ReplaceHtmlEntities');
    end
    
  case 'play'
    nargchk(1,5,nargin);
    opt = opt_proplistToStruct(varargin{:});
    
  case {'saveSettings','loadSettings'}
    nargchk(2,2,nargin);
    opt=[];
    filename = varargin{1};
    misc_checkType(filename,'!CHAR');
    settings_file= [filename '.json'];
    if ~any(ismember('/\', settings_file,'legacy')),
      settings_file= [BTB.Tp.Dir settings_file];
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
      comstr = ['set PATH=' curr_path '& cmd /C "cd ' opt.PyffDir ' & python FeedbackController.py'];
      if ~isempty(opt.A)
        opt.A= strrep(opt.A, '/', filesep);
      end
    elseif strcmp(opt.Os,'unix')
      comstr = ['xterm -e python ' opt.PyffDir  '/FeedbackController.py'];
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
    pyff_sendUdp('init', opt.Host, opt.Port);
    general_port_fields.feedback_receiver= 'pyff';
    
  case 'init'
    pyff_sendUdp('interaction-signal', 's:_feedback', feedback,'command','sendinit');
    
  case 'setdir'
    pyff_sendUdp('interaction-signal', 's:BTB.Tp.Dir',opt.TodayDir, ...
      's:BTB.Tp.Code',opt.VpCode, 's:BASENAME',opt.Basename);
    
  case 'set'
    settings= {};
    fn= fieldnames(vars);
    for ii= 1:numel(fn)
      val = vars.(fn{ii});
      % Take value or (if it is a cell) the value of its first element
      if isempty(val) && ~ischar(val)
        typ= '';  
      elseif ischar(val) || (iscell(val) && ischar(val{1})) || (iscell(val) && iscell(val{1}) && numel(val{1}) && ischar(val{1}{1})) 
        % string or nested string
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
    pyff_sendUdp('interaction-signal', settings{:});
  
  case 'setint'
    settings= {};
    fn= fieldnames(vars);
    typ= 'i:';
    for ii= 1:numel(fn)
      settings= cat(2, settings, {[typ fn{ii}], vars.(fn{ii})});
    end
    pyff_sendUdp('interaction-signal', settings{:});

  case 'play'
    if isempty(varargin),
      ACQ_STARTED= 0;
    else
      ACQ_STARTED= 1;
      bvr_startrecording(varargin{2}, 'AppendTpCode',1, varargin{3:end});
      pause(0.01);
    end
    pyff_sendUdp('interaction-signal', 'command', 'play'); 
    
  case 'stop'
    pyff_sendUdp('interaction-signal', 'command', 'stop'); 
    
  case 'quit'
    pyff_sendUdp('interaction-signal', 'command', 'quit'); 
%     if strcmp(func2str(acquire_func), 'acquire_bv') && ACQ_STARTED,
    if ACQ_STARTED
       bvr_sendcommand('stoprecording');
       ACQ_STARTED= 0;
    end
     
  case 'loadSettings'
    pyff_sendUdp('interaction-signal', 'loadvariables', settings_file);

  case 'saveSettings'
    pyff_sendUdp('interaction-signal', 'savevariables', settings_file);
    
   
end


%% HELP FUNCTIONS 
function str = ReplaceHtmlEntities(str,direction)

  % REPLACE_HTML_ENTITIES -  replaces special symbols such as '<' by their
  %             according HTML entities for correct display in HTML or XML.
  %             Can also perform the backward substitution (replacing HTML
  %             entities by symbols).
  %
  %Usage:
  % str = pyff(str,<direction>)
  %
  %IN:
  % str - input string or cell array of strings
  % direction - direction of substitution, 'forward' (default) replaces
  %             symbols by HTML entities, 'backward' does the opposite 
  %
  %OUT:
  % str - string with special symbols replaced by HTML entities
  %
  %EXAMPLE:
  % replace_html_entities('If A < B then C')

  % Matthias Treder 2010

  if nargin<2, direction = 'forward'; end


  % TO DO ---- REPLACE literal special letters by their ASCII code !!!

  % Specify symbols (ie their ASCII code) and their corresponding entities in matched order
  source = {'´'            'ä'      'Ä'      '<'    '>' ...
    'ö'      'Ö'     };
  target = {'&acute;' '&auml;' '&Auml;' '&lt;' '&gt;' ...
    '&ouml;' '&Ouml;'};
%     '^'   '&circ;'   % <- this is not necessary?

  % For backward substitution switch source and target
  if strcmp(direction,'backward')
    dummy = source;
    source = target;
    target = dummy;
  end

  % Replace
  if ischar(str)
    for kk=1:numel(source)
        str = strrep(str,source{kk},target{kk});
    end
  elseif iscell(str)
    for jj=1:numel(str)
      str{jj} = ReplaceHtmlEntities(str{jj});
    end
  end
end


end
