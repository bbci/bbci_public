global BBCI_DIR PYFF_DIR
global DATA_DIR BBCI_RAW_DIR BBCI_MAT_DIR

BBCI_DIR= fileparts(which(mfilename));
if isempty(BBCI_RAW_DIR),
  BBCI_RAW_DIR= fullfile(DATA_DIR, 'bbciRaw');
end
if ~exist(BBCI_RAW_DIR, 'dir'),
  BBCI_RAW_DIR= '';
end
if isempty(BBCI_MAT_DIR),
  BBCI_MAT_DIR= fullfile(DATA_DIR, 'bbciMat');
end
if ~exist(BBCI_MAT_DIR, 'dir'),
  BBCI_MAT_DIR= '';
end
PYFF_DIR= fullfile(fileparts(BBCI_DIR), 'pyff', 'src');
if ~exist(PYFF_DIR, 'dir'),
  PYFF_DIR= '';
end

addpath(genpath(BBCI_DIR));
rmpath(genpath(fullfile(BBCI_DIR, '.git')));

%startup_bbci_online;
