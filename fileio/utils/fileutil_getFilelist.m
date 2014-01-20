function file= fileutil_getFilelist(spec, varargin)

%% TODO: should also handle: spec is cell array

global BBCI

props = {'Ext',             'eeg',                  'CHAR';
         'Folder',           BBCI.RawDir,           '!CHAR';
         'RequireMatch',     0,                     '!BOOL';
         };

if nargin==0,
  file= props; return
end

opt= opt_proplistToStruct(varargin{:});
[opt,isdefault] = opt_setDefaults(opt, props);
opt_checkProplist(opt, props);
misc_checkType(spec,'CHAR');

if isdefault.Ext,
  is= find(spec=='.', 1, 'last');
  if ~isempty(is) && is<length(spec) && is>=length(spec)-4,
    ext= spec(is+1:end);
    if ~ismember('*',ext,'legacy') && ~ismember('/',ext,'legacy'),
      opt.Ext= ext;
    end
  else
    spec= [spec '.' opt.Ext];
  end
else
  spec= [spec '.' opt.Ext];
end

if isdefault.Folder,
  switch(lower(opt.Ext)),
   case {'eeg','vhdr','vmrk'},
    opt.Folder= BBCI.RawDir;
   case 'mat',
    opt.Folder= BBCI.MatDir;
  end
end

[filepath, dmy]= fileparts(spec);
if ~fileutil_isAbsolutePath(spec),
  spec= [opt.Folder filesep spec];
end

dd= dir(spec);
if isempty(dd),
  if opt.RequireMatch,
    msg= sprintf('no files matching ''%s'' found', spec);
    error(msg);
  end
  file= {};
  return;
end

if length(dd)==1,
  file= strcat(filepath, filesep, dd.name);
else
  file= strcat(filepath, filesep, {dd.name});
end
if ~isdefault.Ext,
  file= strrep(file, ['.' opt.Ext], '');
end
