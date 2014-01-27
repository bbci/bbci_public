function startup_bbci_toolbox(varargin)

global BBCI

% Find directory of the BBCI Toolbox and path it to the path
BBCI_DIR= fileparts(which(mfilename));
addpath(genpath(BBCI_DIR));
rmpath(genpath(fullfile(BBCI_DIR, '.git')));
BBCI_PRIVATE_DIR= fullfile(fileparts(BBCI_DIR), 'bbci_private');

BBCI= opt_proplistToStruct(varargin{:});
if ~isfield(BBCI, 'TypeChecking'),
  BBCI.TypeChecking= 1;
end
BBCI= opt_setDefaults(BBCI, {'DataDir'   '/home/bbci/data/'   'CHAR'});
if ~exist(BBCI.DataDir, 'dir'),
  warning('Optional argument ''DataDir'' should specify an existing folder.');
end

% Guess what the location of other directories could be
BBCI_RAW_DIR= fullfile(BBCI.DataDir, 'bbciRaw/');
if ~exist(BBCI_RAW_DIR, 'dir'),
  BBCI_RAW_DIR= BBCI.DataDir;
end
BBCI_MAT_DIR= fullfile(BBCI.DataDir, 'bbciMat/');
if ~exist(BBCI_MAT_DIR, 'dir'),
  BBCI_MAT_DIR= BBCI.DataDir;
end
PYFF_DIR= fullfile(fileparts(BBCI_DIR), 'pyff', 'src');
if ~exist(PYFF_DIR, 'dir'),
  PYFF_DIR= '';
end

props= {'Dir'            BBCI_DIR          'CHAR';
        'DataDir'        ''                'CHAR';
        'RawDir'         BBCI_RAW_DIR      'CHAR';
        'MatDir'         BBCI_MAT_DIR      'CHAR';
        'PrivateDir'     BBCI_PRIVATE_DIR  'CHAR';
        'TmpDir'         ''                'CHAR';
        'PyffDir'        PYFF_DIR          'CHAR';
        'FigDir'         ''                'CHAR';
        'Tp'             struct            'STRUCT';
        'Acq'            struct            'STRUCT';
        'History'        1                 '!BOOL';
        'TypeChecking'   1                 '!BOOL'
       };
[BBCI, isdefault]= opt_setDefaults(BBCI, props);

private_folders_to_add= {'utils', 'startup'};
for kk= 1:length(private_folders_to_add),
  folder= fullfile(BBCI.PrivateDir, private_folders_to_add{kk});
  if exist(folder, 'dir'),
    addpath(genpath(folder));
  end
end

if isdefault.TmpDir
  BBCI.TmpDir= fullfile(BBCI.DataDir, 'tmp');
  if ~exist(BBCI.TmpDir, 'dir'),
    fprintf('!! Default TEMP dir not existing at\n  %s\n', BBCI.TmpDir);
    fprintf('!! Setting TEMP dir to ''''\n');
    BBCI.TmpDir= '';
  end
end

% Information about the test person (Tp)
props= {'Dir'       ''    'CHAR'
        'Code'      ''    'CHAR'
       };
BBCI.Tp= opt_setDefaults(BBCI.Tp, props);

% Information about data acquistion
props= {'Prefix'          'a'    'CHAR'
        'StartLetter'     'a'    'CHAR'
        'Dir'             ''     'CHAR'
        'Geometry'        []     'DOUBLE[1 4]'
        'IoAddr'          []     'INT'
        'IoLib'           ''     'CHAR'
       };
BBCI.Acq= opt_setDefaults(BBCI.Acq, props);

evalin('base', 'global BBCI');
