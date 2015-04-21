function startup_bbci_toolbox(varargin)

global BTB

% Find directory of the BBCI Toolbox and path it to the path
BBCI_DIR= fileparts(which(mfilename));
addpath(genpath(BBCI_DIR));
rmpath(genpath(fullfile(BBCI_DIR, '.git')));
BBCI_PRIVATE_DIR= fullfile(fileparts(BBCI_DIR), 'bbci_private');

BTB= opt_proplistToStruct(varargin{:});

if ~isfield(BTB, 'TypeChecking'),
  BTB.TypeChecking= 1;
end
BTB= opt_setDefaults(BTB, {'DataDir'   '/home/bbci/data/'   'CHAR'});
if ~exist(BTB.DataDir, 'dir'),
  warning('Optional argument ''DataDir'' should specify an existing folder.');
end

% Guess what the location of other directories could be
BBCI_RAW_DIR= fullfile(BTB.DataDir, 'bbciRaw/');
if ~exist(BBCI_RAW_DIR, 'dir'),
  BBCI_RAW_DIR= BTB.DataDir;
end
BBCI_MAT_DIR= fullfile(BTB.DataDir, 'bbciMat/');
if ~exist(BBCI_MAT_DIR, 'dir'),
  BBCI_MAT_DIR= BTB.DataDir;
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
[BTB, isdefault]= opt_setDefaults(BTB, props);

if exist(BTB.PrivateDir, 'dir'),
  private_folders_to_add= {'utils', 'startup'};
  for kk= 1:length(private_folders_to_add),
    folder= fullfile(BTB.PrivateDir, private_folders_to_add{kk});
    if exist(folder, 'dir'),
      addpath(genpath(folder));
    end
  end
end


% Information about the test person (Tp)
props= {'Dir'    BTB.TmpDir  'CHAR'
        'Code'   ''          'CHAR'
       };
BTB.Tp= opt_setDefaults(BTB.Tp, props);

% Information about data acquistion
props= {'Prefix'          'a'                     'CHAR'
        'StartLetter'     'a'                     'CHAR'
        'Dir'             BTB.TmpDir              'CHAR'
        'Geometry'        []                      'DOUBLE[1 4]'
        'TriggerFcn'      @bbci_trigger_parport   'FCN'
        'TriggerParam'    {}                      'CELL'
       };
BTB.Acq= opt_setDefaults(BTB.Acq, props);

switch computer
 case 'PCWIN'
  BTB.Acq.IoLib= which('inpout32.dll');
 case 'PCWIN64'
  BTB.Acq.IoLib= which('inpoutx64.dll');
end

if isfield(BTB.Acq, 'IoLib') && isfield(BTB.Acq, 'IoAddr'),
  if isempty(BTB.Acq.TriggerParam) && ...
      isequal(BTB.Acq.TriggerFcn, @bbci_trigger_parport),
    BTB.Acq.TriggerParam= {BTB.Acq.IoLib, BTB.Acq.IoAddr};
  end
else
  fprintf('Parport not installed. Triggers will just be printed.\n');
  BTB.Acq.TriggerFcn= @bbci_trigger_print;
end

% basti was here.

evalin('base', 'global BTB');
