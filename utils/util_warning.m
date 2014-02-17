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
% STATE= util_warning(MSG, ID, <OPT>)
%
%Input:
% MSG:  (string) the warning message, or 'off' or 'query', see the
%       help of 'warning'.
% ID:   (string) 
% OPT:  (struct(proplist) Property/value list or struct of optional parameters:
%   'Interval': Warnings that appear earlier than this interval of time [s]
%        after a warning (for the same ID) are suppressed. Default 10*60. 
%   'File': Display this as the file that issued the warning.
%        Default: name of the calling function.
%
%
%Example 1 (within a matlab function):
% util_warning('outer model selection sucks', 'validation');
%
%Example 2:
% wstat= util_warning('off', 'validation');
% %% ... some code admittedly producing 'validation' warnings ...
% util_warning(wstat);


persistent id_list last_warning

st= dbstack;
if length(st)>1,
  default_File= st(2).name;
else
  default_File= '';
end
props= {'File'       default_File   'CHAR';
        'Interval'   10*60          '!DOUBLE[1]';
       };
opt= opt_proplistToStruct(varargin{:});
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

if isempty(opt.File), 
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
      state= warning('query', ['BBCI:' id]);
    end
    warning('off', ['bbci:' id]);
  elseif strcmp(msg, 'query'),
    state= warning('query', ['BBCI:' id]);
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
