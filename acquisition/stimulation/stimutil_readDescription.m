function desc= stimutil_readDescription(file,varargin)

%STIMUTIL_READDESCRIPTION - Reads the description of an experiment from a
%                           text file
%
%Synopsis:
%  desc= stimutil_readDescription(file,OPT)
%
%Arguments:
%  OPT: struct or property/value list of optional properties
%   'Folder': directory of the thext file
%   'Suffix': suffix of the text file (default .txt)
%

global BTB


props= {'Folder'  fullfile(BTB.PrivateDir, 'acquisition','data','task_descriptions') 'CHAR|CELL{CHAR}'
        'Suffix'	'.txt'                                          'CHAR|DOUBLE'};
        
if nargin==0,
  desc = props; 
  return
end

opt= opt_proplistToStruct(varargin{:});
opt= opt_setDefaults(opt, props);
opt_checkProplist(opt, props);

if fileutil_isAbsolutePath(file),
	filename= [file opt.Suffix];
else
	filename= fullfile(opt.Folder, [file opt.Suffix]);
end

desc= textread(filename,'%s','delimiter','\n');
