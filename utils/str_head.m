function cstr= str_head(cstr,varargin)
%head= strh_ead(str,<delim>)
%
% returns the string up to (not including) the first space
% works also for cells of strings
% 'delim' -  delimiter of the string head, e.g. '_' (default ' ')

if nargin<2
    delim = ' ';
else
    delim = varargin{1};
end

if ~iscell(cstr), 
  cstr= str_head({cstr},delim); 
  cstr= cstr{1};
  return
end

for il= 1:length(cstr),
  cstr{il}= cstr{il}(1:min([end findstr(delim, cstr{il})-1]));
end
