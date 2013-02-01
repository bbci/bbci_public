function startup_bbci_toolbox(varargin)

global BBCI

% Find directory of the BBCI Toolbox and path it to the path
BBCI_DIR= [fileparts(which(mfilename)) filesep];
addpath(genpath(BBCI_DIR));
rmpath(genpath(fullfile(BBCI_DIR, '.git')));

BBCI= opt_proplistToStruct(varargin{:});
if ~isfield(BBCI, 'TypeChecking'),
  BBCI.TypeChecking= 1;
end
BBCI= opt_setDefaults(BBCI, {'DataDir'  '/home/bbci/data/'});

% Guess what the location of other directories could be
BBCI_RAW_DIR= fullfile(BBCI.DataDir, 'bbciRaw/');
if ~exist(BBCI_RAW_DIR, 'dir'),
  BBCI_RAW_DIR= '';
end
BBCI_MAT_DIR= fullfile(BBCI.DataDir, 'bbciMat/');
if ~exist(BBCI_MAT_DIR, 'dir'),
  BBCI_MAT_DIR= '';
end
TMP_DIR= fullfile(BBCI.DataDir, 'tmp');
if ~exist(TMP_DIR, 'dir'),
  TMP_DIR= '';
end
PYFF_DIR= fullfile(fileparts(BBCI_DIR), 'pyff', 'src');
if ~exist(PYFF_DIR, 'dir'),
  PYFF_DIR= '';
end

props= {'Dir'            BBCI_DIR        'CHAR';
        'DataDir'        ''              'CHAR';
        'RawDir'         BBCI_RAW_DIR    'CHAR';
        'MatDir'         BBCI_MAT_DIR    'CHAR';
        'TmpDir'         TMP_DIR         'CHAR';
        'PyffDir'        PYFF_DIR        'CHAR';
        'FigDir'         ''              'CHAR';
        'Tp'             struct          'STRUCT';
        'Acq'            struct          'STRUCT';
        'History'        1               '!BOOL';
        'TypeChecking'   1               '!BOOL'
       };
BBCI= opt_setDefaults(BBCI, props);

% Information about the test person (Tp)
props= {'Dir'       ''   'CHAR'
        'Code'      ''   'CHAR'
        'Geometry'  []   'DOUBLE[1 4]'
       };
BBCI.Tp= opt_setDefaults(BBCI.Tp, props);

props= {'Prefix'          'a'    'CHAR'
        'StartLetter'     'a'    'CHAR'
        'Dir'             ''     'CHAR'
        };
BBCI.Acq= opt_setDefaults(BBCI.Acq, props);

evalin('base', 'global BBCI');
