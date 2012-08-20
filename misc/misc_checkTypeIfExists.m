function misc_checkTypeIfExists(propname, typeDefinition)
%MISC_CHECKTYPEIFEXISTS - Check variable if it does exist
%
%Synopsis:
%  misc_checkTypeIfExists(VARNAME, TYPEDEF)
%
%See the help of misc_checkType. The only difference is that this
%function does not throw an error, if the specified variable does not exist.


global BBCI_TYPECHECKING

if ~BBCI_TYPECHECKING, return; end

misc_checkType('propname', 'CHAR');
misc_checkType('typeDefinition', 'CHAR');

exists= evalin('caller', ['exist('' propname '', ''var'')']);
if exists,
  variable= evalin('caller', propname);
  misc_checkType(variable, typeDefinition, propname);
end
