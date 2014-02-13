function out= pyff_loadSettings(file)
%PYFF_LOADSETTINGS - Load variable settings from a JSON file
%
%OUT= pyff_loadSettings(FILE)
%
%Arguments:
% FILE: Filename of the json file. Suffix '.json' is appended is no
%    suffix is given.
%
%Output:
% OUT: Propertylist containing all variables of the JSON file. Use
% pyff('set',OUT) to send them to Pyff.

misc_checkType(file,'!CHAR');

global BTB

if ~exist('p_json', 'file'),
  %addpath([BCI_DIR 'import/json']);
  addpath([BTB.Dir 'PRELIMINARY' filesep 'json']);
end

if ~ismember('.', file,'legacy'),
  file= strcat(file, '.json');
end
if ~fileutil_isAbsolutePath(file),
  file= strcat([BTB.Acq.Dir 'setups\' file]);
end

fid= fopen(file, 'rt'); 
if fid==-1,
  error(sprintf('file <%s> could not be opened.', file));
end
inString = fscanf(fid,'%c'); 
fclose(fid);
out= p_json(inString);
