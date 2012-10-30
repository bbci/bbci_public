function out= util_unixCmd(cmd, action)
%UTIL_UNIXCMD - Run a unix command and check for errors
%
%Synopsis:
% util_unixCcmd(CMD, <ACTION>)
%
%Arguments:
% CMD:    String, the unix command to be executed
% ACTION: String, printed in case of an error


if ~isunix,
  warning('attempt to execute unix command in non-unix system');
  return;
end

if nargin<2,
  action= '';
end

[stat,out]= unix(cmd);
if stat~=0,
  error(sprintf('error %s (%s -> %s)', action, cmd, out));
end

if nargout==0,
  clear out
end
