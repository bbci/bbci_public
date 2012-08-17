function oldstate= bbci_typechecking(onoff)
%BBCI_TYPECHECKING - Switch type checking on or off
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


global BBCI_TYPECHECKING

oldstate= BBCI_TYPECHECKING;

if nargin==0,
  onoff= 'on';
end

BBCI_TYPECHECKING= onoff;

switch(BBCI_TYPECHECKING),
 case {1, 'on'},
  BBCI_TYPECHECKING= 1;
 case {0, 'off'},
  BBCI_TYPECHECKING= 0;
 otherwise
  error('only ''on'' and ''off'' are allowed arguments');
end

if nargout==0,
  clear oldstate;
end
