function str= stimutil_waitForInput(varargin)
%STIMUTIL_WAITFORINPUT - Wait for a specific input from keyboard
%
%Synopsis:
%  STR= stimutil_waitForInput(OPT)
%
%Arguments:
%  OPT: struct or property/value list of optional properties
%   'phrase': phrase that needs to be input before this function returns
%       (excluding <RETURN>, which is always required at the end), default: '';
%   'msg': Message template that prompts the user, 
%       default 'Press "%s<RETURN>" %s > '. The first %s is filled with
%       OPT.phrase, the second %s is filled with OPT.msg_next.
%   'msg_next': see above, default: 'to continue'
%
%Example:
%  stimutil_waitForInput('phrase','go', 'msg_next','to go to the next run');


props= {'phrase'    ''                          'CHAR'
        'msg'       'Press "%s<RETURN>" %s > '	'CHAR'
        'msg_next'  'to continue'               'CHAR'
        }
        
if nargin==0,
  str = props; 
  return
end

opt= opt_proplistToStruct(varargin{:});
[opt, isdefault] = opt_setDefaults(opt, props);
opt_checkProplist(opt, props);

if isdefault.msg,
  msg= sprintf(opt.msg, opt.phrase, opt.msg_next);
else
  msg= opt.msg;
end

str= 'xXqQimpossibleQqXx';

while ~strcmp(str, opt.phrase),
  str= input(msg, 's');
end
