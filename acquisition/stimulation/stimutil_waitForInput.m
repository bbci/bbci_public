function str= stimutil_waitForInput(varargin)
%STIMUTIL_WAITFORINPUT - Wait for a specific input from keyboard
%
%Synopsis:
%  STR= stimutil_waitForInput(OPT)
%
%Arguments:
%  OPT: struct or property/value list of optional properties
%   'Phrase': phrase that needs to be input before this function returns
%       (excluding <RETURN>, which is always required at the end), default: '';
%   'Msg': Message template that prompts the user, 
%       default 'Press "%s<RETURN>" %s > '. The first %s is filled with
%       OPT.Phrase, the second %s is filled with OPT.MsgNext.
%   'MsgNext': see above, default: 'to continue'
%
%Example:
%  stimutil_waitForInput('phrase','go', 'MsgNext','to go to the next run');


props= {'Phrase'    ''                          'CHAR';
        'Msg'       'Press "%s<RETURN>" %s > '	'CHAR';
        'MsgNext'  'to continue'               'CHAR';
        };
        
if nargin==0,
  str = props; 
  return
end

opt= opt_proplistToStruct(varargin{:});
[opt, isdefault] = opt_setDefaults(opt, props);
opt_checkProplist(opt, props);

if isdefault.Msg,
  msg= sprintf(opt.Msg, opt.Phrase, opt.MsgNext);
else
  msg= opt.Msg;
end

str= 'xXqQimpossibleQqXx';

while ~strcmp(str, opt.Phrase),
  str= input(msg, 's');
end
