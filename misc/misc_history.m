function obj = misc_history(obj)
%MISC_HISTORY - Records the history of BTB toolbox function calls that
%               affected the object.
%
%Synopsis:
%  MISC_HISTORY(OBJ)
%
%Arguments:
%  OBJ:     struct with neuro data, or montage, or marker
%
%Returns:
%  OBJ:     struct with extra history entry in the substruct .history with
%           the following fields:
% 
%  fcn:           function handle
%  fcn_params:    names of named function parameters.
%  varargin:      optional arguments
%  date:          date the function was executed
%
%  All named function arguments also appear as fields except for the object
%  that is modified (e.g. the EEG struct). The latter appears in the
%  parameter list as 'obj'. (note: to avoid confusion proc_ functions
%  should not have another parameter called 'obj')
%
% Note: misc_history saves all arguments passed to functions unless they
% exceed a certain byte size.
%
%See also: misc_applyHistory

% 08-2012 Matthias Treder
global BTB

if ~isempty(BTB.History) && BTB.History==0 ||isempty(obj)
  return
end

misc_checkType(obj,'STRUCT');

if isfield(obj,'history')
  ht = obj.history;
  N = numel(ht)+1;
else
  ht = cell(1,1);  
  N = 1;
end
ht{N} = struct();

objname = inputname(1);  % Name of object in caller's workspace

maxSize = 10*1000*1000;   % max byte size of arguments saved in history
% Get function name (of caller)
ST = dbstack('-completenames',1);
ht{N}.fcn = eval(['@' ST(1).name]);

% Find labels of function parameters (arguments)
code = (evalc(['type ' ST(1).name])); % get function code
expr = ['^\s*function s*\[*\s*(\w+|\s*|,)*\]*\s*=\s*' ST(1).name '\s*\((\w+|\s+|,)*\)'];
token = regexpi(code,expr,'tokens');
token = strrep(token{1}{end},' ','');  % remove whitespace
token = regexp(token,',','split');   % split arguments by commas

% Remove params that have not been used (nargin < number of params)
nActualArguments= evalin('caller', 'nargin');
if nActualArguments < numel(token)
  token(nActualArguments+1:end) = [];
end

ht{N}.fcn_params = token(~ismember(token,'varargin','legacy'));

% Get argument values for named arguments
for ii=1:numel(ht{N}.fcn_params)
  if strcmp(ht{N}.fcn_params{ii},objname)
    ht{N}.fcn_params{ii} = 'obj';  % always call the dat/epo/cnt struct obj
  else
    s =evalin('caller',['whos(''' token{ii} ''')']);  % Get size of variable
    if s.bytes > maxSize
       ht{N}.(ht{N}.fcn_params{ii}) = sprintf('variable exceeds maximum size %d kb',maxSize/1000);
    else
       ht{N}.(ht{N}.fcn_params{ii}) = evalin('caller',ht{N}.fcn_params{ii});
    end
  end
end

% Get optional arguments (varargin)
if any(ismember(token,'varargin','legacy'))
  va = evalin('caller','varargin');
  % Check size of variable
  s=evalin('caller','whos(''varargin'')');
  if s.bytes > maxSize
     ht{N}.varargin_note = sprintf('varargin exceeds maximum size %d kb',maxSize/1000);
  else
    for ii=1:numel(va)
        ht{N}.(sprintf('varargin%d',ii)) = va{ii};
    end
  end
end

ht{N}.date= datestr(now,0);
obj.history = ht;