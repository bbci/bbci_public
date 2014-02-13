function oldstate= bbci_typechecking(onoff)
%BTB.TypeChecking - Switch type checking on or off
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


global BTB

if isempty(BTB.TypeChecking),
  oldstate= 'on';
else
  oldstate= BTB.TypeChecking;
end

if nargin==0,
  onoff= 'on';
end

BTB.TypeChecking= onoff;

switch(BTB.TypeChecking),
 case {1, 'on'},
  BTB.TypeChecking= 1;
 case {0, 'off'},
  BTB.TypeChecking= 0;
 otherwise
  error('only ''on'' and ''off'' are allowed arguments');
end

if nargout==0,
  clear oldstate;
end
