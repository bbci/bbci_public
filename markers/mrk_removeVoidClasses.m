function [mrk, ev]= mrk_removeVoidClasses(mrk)
%mrk= mrk_selectEvents(mrk)
%
% requires a field 'y' containing the class labels in mrk.

misc_checkType(mrk, 'STRUCT(time y)');

nonvoidClasses= find(any(mrk.y,2));
if length(nonvoidClasses)<size(mrk.y,1),
  msg= sprintf('void classes removed, %d classes remaining', ...
                  length(nonvoidClasses));
%   util_warning(msg, 'mrk', mfilename);
  warning(msg, 'mrk');
  mrk.y= mrk.y(nonvoidClasses,:);
  if isfield(mrk, 'className'),
    mrk.className= {mrk.className{nonvoidClasses}};
  end
end
