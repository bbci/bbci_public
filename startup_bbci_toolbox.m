function startup_bbci_toolbox(varargin)

global BTB


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


if exist(BTB.PrivateDir, 'dir'),
  private_folders_to_add= {'utils', 'startup'};
  for kk= 1:length(private_folders_to_add),
    folder= fullfile(BTB.PrivateDir, private_folders_to_add{kk});
    if exist(folder, 'dir'),
      addpath(genpath(folder));
    end
  end
end

if isdefault.TmpDir
  BTB.TmpDir= fullfile(BTB.DataDir, 'tmp');
  if ~exist(BTB.TmpDir, 'dir'),
    fprintf('!! Default TEMP dir not existing at\n  %s\n', BTB.TmpDir);
    fprintf('!! Setting TEMP dir to ''''\n');
    BTB.TmpDir= '';
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

% basti was here

if isfield(BTB.Acq, 'IoLib') && isfield(BTB.Acq, 'IoAddr'),
  if isempty(BTB.Acq.TriggerParam) && ...
      isequal(BTB.Acq.TriggerFcn, @bbci_trigger_parport),
    BTB.Acq.TriggerParam= {BTB.Acq.IoLib, BTB.Acq.IoAddr};
  end
else
  fprintf('Parport not installed. Triggers will just be printed.\n');
  BTB.Acq.TriggerFcn= @bbci_trigger_print;
end


evalin('base', 'global BTB');
