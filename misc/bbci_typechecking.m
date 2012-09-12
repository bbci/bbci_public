function oldstate= bbci_typechecking(onoff)
%BBCI.TypeChecking - Switch type checking on or off
%
%Synopsis:
% bbci_typechecking(<SWITCH>)
% OLD_STATE= bbci_typechecking(<SWITCH>)
%
%Arguments:
% SWITCH: CHAR|BOOL - may be 'on'/1 (default) or 'off'/0
%
%Returns:
% OLD_STATE: CHAR - State ('on'/'off') that type checking had before
%
%Example:
% tcstate= bbci_typechecking('off');
% % do time-critical things 
% bbci_typechecking(tcstat);


global BBCI

if isempty(BBCI.TypeChecking),
  oldstate= 'on';
else
  oldstate= BBCI.TypeChecking;
end

if nargin==0,
  onoff= 'on';
end

BBCI.TypeChecking= onoff;

switch(BBCI.TypeChecking),
 case {1, 'on'},
  BBCI.TypeChecking= 1;
 case {0, 'off'},
  BBCI.TypeChecking= 0;
 otherwise
  error('only ''on'' and ''off'' are allowed arguments');
end

if nargout==0,
  clear oldstate;
end
