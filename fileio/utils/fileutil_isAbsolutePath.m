function bool= fileutil_isAbsolutePath(file)
% FILEUTIL_ISABSOLUTEPATH - Determines whether a path is absolute or relative.
%
% Synopsis:
%   bool = isabsolutepath(FILE)
%
% Returns: 1 (absolute path) or 0 (relative path)
%
misc_checkType(file,'!CHAR');

bool= (isunix &&  file(1)==filesep) || (ispc && file(2)==':');
