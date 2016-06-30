function ok = misc_isproplist(variable)
% MISC_ISPROPLIST - Checks for property/value list or property struct
%
%Synopsis:
%  OK= misc_isproplist(VARIABLE)
%
%Argument:
%  VARIABLE: [any type] variable to be checked
%
%Returns
%  OK: [BOOLEAN] true if VARIABLE is a property/value list or a struct


if ( iscell(variable) && isempty(variable) ) || ...
      ( isstruct(variable) && length(variable)==1 ),
  ok= 1;
elseif iscell(variable) && ndims(variable)==2 && size(variable,1)==1 && ...
        mod(length(variable),2)==0,
  ok= all(cellfun(@ischar, variable(1:2:end)));
else
  ok= 0;
end
