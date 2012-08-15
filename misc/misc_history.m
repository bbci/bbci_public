function obj = misc_history(obj)
%MISC_HISTORY - Records the history of BBCI toolbox function calls that
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
%  that is modified (e.g. the EEG struct).
%
% Note: misc_history saves all arguments passed to functions unless they
% exceed a certain byte size.
%
% See also: misc_history_recall

% Matthias Treder 2012

global BBCI_HISTORY

if ~isempty(BBCI_HISTORY) && BBCI_HISTORY==0
  return
end

maxSize = 10*1000*1000;   % max byte size of arguments saved in history

if isfield(obj,'history')
  ht = obj.history;
  N = numel(ht)+1;
else
  ht = cell(1,1);  
  N = 1;
end
ht{N} = struct();

objname = inputname(1);  % Name of object in caller's workspace

% Get function name (of caller)
ST = dbstack('-completenames',1);
ht{N}.fcn = eval(['@' ST(1).name]);

% Find labels of function parameters (arguments)
code = (evalc(['type ' ST(1).name])); % get function code
expr = ['^\s*function s*\[*\s*(\w+|\s*|,)*\]*\s*=\s*' ST(1).name '\s*\((\w+|\s+|,)*\)'];
token = regexpi(code,expr,'tokens');
token = strrep(token{1}{end},' ','');  % remove whitespace
token = regexp(token,',','split');   % split arguments by commas

ht{N}.fcn_params = setdiff(token,'varargin','stable');

% Get argument values for named arguments
for ii=1:numel(token)
    if ~strcmp(token{ii},'varargin') && ~strcmp(token{ii},objname)
        s=evalin('caller',['whos(''' token{ii} ''')']);  % Get size of variable
        if s.bytes > maxSize
           ht{N}.(token{ii}) = sprintf('variable exceeds maximum size %d kb',maxSize/1000);
        else
           ht{N}.(token{ii}) = evalin('caller',token{ii});
        end
    end
end

% Get optional arguments (varargin)
if any(ismember(token,'varargin'))
%   ht{N}.varargin = evalin('caller','varargin');
  va = evalin('caller','varargin');
  for ii=1:numel(va)
      ht{N}.(sprintf('varargin%d',ii)) = va{ii};
  end
end

ht{N}.date= datestr(now,0);
obj.history = ht;