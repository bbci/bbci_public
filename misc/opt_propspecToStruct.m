function opt= opt_propspecToStruct(propspec)
% OPT_PROPSPECTOSTRUCT - Make options struct from property specification
%
%Synopsis:
%  OPT= opt_propspecToStruct(PROPSPEC)
%
%Arguments:
%  PROPSPEC - Property specification
%
%Returns:
%  OPT:  STRUCT with (new) fields created from the property/value list
%
%See also misc_checkType, opt_setDefaults, opt_proplistToStruct

% 06-2012 Benjamin Blankertz


misc_checkType(propspec, 'PROPSPEC');

opt= [];
if nargin==0,
  return;
end

nFields= size(propspec,1);
for ff= 1:nFields,
  fld= propspec{ff,1};
  opt.(fld)= propspec{ff,2};
end
