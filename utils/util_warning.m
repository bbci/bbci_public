function state= util_warning(msg, id, varargin)
%UTIL_WARNING - Display warning message
%
%Description:
% Essentially this function is just a work-around such that one can
% use the increased functionality of the warning function of Matlab R>=13,
% while having programs that still run under Matlab R<13.
% Furthermore, this function allows to suppress warnings which follow each
% other within a short interval of time.
%
%Usage:
% STATE= util_warning(MSG, ID, <FILE>)
% STATE= util_warning(MSG, ID, <OPT>)
%
%Input:
% MSG:  (string) the warning message, or 'off' or 'query', see the
%       help of 'warning'.
% ID:   (string) 
% FILE: (string) filename of the function in which the warning is produced.
%       (A function can determine its name via function 'mfilename'.)
% OPT:  (struct(proplist) Property/value list or struct of optional parameters:
%   'interval': Warnings that appear earlier than this interval of time [s]
%        after a warning (for the same ID) are suppressed. Default 10*60. 
%   'file':

%
%Example 1 (within a matlab function):
% util_warning('outer model selection sucks', 'validation', mfilename);
%
%Example 2:
% wstat= util_warning('off', 'validation');
% %% ... some code consciously producing 'validation' warnings ...
% util_warning(wstat);
%
%See also warning, mfilename


persistent id_list last_warning

props= {'File',     ''      'CHAR';
        'Interval'  10*60   'DOUBLE';
       };

if length(varargin)==1 && ischar(varargin{1}),
  opt= struct('file', varargin{1});
else
  opt= opt_proplistToStruct(varargin{:});
end
opt= opt_setDefaults(opt, props, 1);

misc_checkType(msg, 'CHAR');
misc_checkType(id, 'CHAR');

this_warning= clock;
id_idx= strmatch(msg, id_list, 'exact');
if isempty(id_idx),
  id_list= cat(2, id_list, {msg});
  last_warning= [last_warning; this_warning];
else 
  if etime(this_warning, last_warning(id_idx,:)) < opt.Interval,
    return;
  end
  last_warning(id_idx,:)= this_warning;
end

if ~exist(opt.File), 
  ff= ''; 
else
  ff= [opt.File ': '];
end

a= sscanf(getfield(ver('MATLAB'), 'Release'), '(R%d)');
if a>=13,
  if isstruct(msg),
    warning(msg);
  elseif strcmp(msg, 'off'),
    if nargout>0,
      state= warning('query', ['bbci:' id]);
    end
    warning('off', ['bbci:' id]);
  elseif strcmp(msg, 'query'),
    state= warning('query', ['bbci:' id]);
  else
    warning(['bbci:' id], [ff msg]);
  end
else
  if ~isempty(msg) & isempty(strmatch(msg, {'off','query'})),
    state= warning([ff msg]);
  else
    state= [];
  end
end
