function [varargout] = acq_makeDataFolder(varargin)
%ACQ_MAKEDATAFOLDER - Create a folder for saving EEG data
% 
%Synopsis:
% folder= acq_makeDataFolder;
% folder= acq_makeDataFolder(OPT);
%
%Arguments:
% 'tmp' : creates temporal directory
% OPT: struct or property/value list of optinal properties:
%
%Returns:
% folder: name of the folder in which EEG signals will be saved
%Side effect:
% Set global variables VP_CODE, TODAY_DIR
%
% XX-XX Benjamin Blankertz 
% 06-12 Javier Pascual. Updated. Created new function getSubjectcode

global EEG_RAW_DIR VP_CODE TODAY_DIR
global ACQ_PREFIX_LETTER ACQ_LETTER_START ACQ_LETTER_RESERVED

VP_CODE = [];

%% Get the date
today_vec= clock;
today_str= sprintf('%02d_%02d_%02d', today_vec(1)-2000, today_vec(2:3));

if length(varargin)==1 & isequal(varargin{1},'tmp'),
  TODAY_DIR= [EEG_RAW_DIR 'Temp_' today_str '\'];
  if ~exist(TODAY_DIR, 'dir'),
    mkdir_rec(TODAY_DIR);
  end
  return;
end

if isempty(ACQ_LETTER_START),
  ACQ_LETTER_START= 'a';
end


props = {   'multiple_folders'	0	'BOOL'          
            'log_dir'           0   'BOOL'};

if nargin==0,
    varargout{1} = opt_catProps(props, getSubjectCode); 
    return;
end;

opt= opt_proplistToStruct(varargin{:});
[opt,isdefault] = opt_setDefaults(opt, props);
opt_checkProplist(opt, props);

%% Check whether a directory exists that is to be used
dd= dir([EEG_RAW_DIR 'VP???_' today_str '*']);

if ~opt.multiple_folders & length(dd)>1,
  error('multiple folder of today exist, but opt.multiple_folder is set to 0.');
end

k= 0;

while isempty(VP_CODE) & k<length(dd),
  k= k+1;
  de= dir([EEG_RAW_DIR dd(k).name '\*.eeg']);
  if ~opt.multiple_folders | isempty(de),
    is= find(dd(k).name=='_', 1, 'first');
    VP_CODE= dd(k).name(1:is-1);
    fprintf('!!Using existing directory <%s>!!\n', dd(k).name);
  end
end

% if VP_CODE is empty, we generate a new one
if(isempty(VP_CODE)),
    VP_CODE = getSubjectCode(   'prefix_letter', ACQ_PREFIX_LETTER, ...
                                'letter_start', ACQ_LETTER_START, ...
                                'letter_reserved', ACQ_LETTER_RESERVED);
end;

TODAY_DIR= [EEG_RAW_DIR VP_CODE '_' today_str filesep];

if ~exist(TODAY_DIR, 'dir'),
  mkdir_rec(TODAY_DIR);
end

if opt.log_dir,
  global LOG_DIR
  LOG_DIR= [TODAY_DIR 'log\'];
  if ~exist([TODAY_DIR 'log']),
    mkdir_rec(LOG_DIR);
  end
end

fprintf('EEG data will be saved in <%s>.\n', TODAY_DIR);
