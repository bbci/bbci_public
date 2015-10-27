function bool= util_isnan(X)
%UTIL_ISNAN - Tests if an input argument is a numeric NaN value
%
%Description:
% This function is an extension of Matlab's isnan function. It also accepts
% cell arrays (on which it works recursively on the elements) and also other
% non-numeric input (for which it returns 'false').
% In the BBCI toolbox it was introduced to cope with Matlab's new graphic
% handle objects.
%
%Synopsis:
% BOOL= util_isnan(X)
%
%Argument:
% X: any type
%
%Output:
% BOOL: Boolean value. If input X is an array or cell array, the output BOOL
%       is of the same size.

% 2015-10 benjamin.blankertz@tu-berlin.de


if isnumeric(X),
  bool= isnan(X);
elseif iscell(X),
  bool= cellfun(@util_isnan, X, 'UniformOutput',false);
else
  bool= 0;
end
