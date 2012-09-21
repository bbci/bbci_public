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
% Set global variables BBCI.Tp.Code, BBCI.Tp.Dir
%
% XX-XX Benjamin Blankertz 
% 06-12 Javier Pascual. Updated. Created new function getSubjectcode


global BBCI

%BBCI.Tp.Code = [];

%% Get the date
today_vec= clock;
today_str= sprintf('%02d_%02d_%02d', today_vec(1)-2000, today_vec(2:3));

if length(varargin)==1 & isequal(varargin{1},'tmp'),
  BBCI.Tp.Dir= [BBCI.RawDir 'Temp_' today_str '\'];
  if ~exist(BBCI.Tp.Dir, 'dir'),
    mkdir_rec(BBCI.Tp.Dir);
  end
  return;
end

if isempty(BBCI.Acq.StartLetter),
  BBCI.Acq.StartLetter= 'a';
end


props = {'multiple_folders'	0	'BOOL'};

if nargin==0,
  varargout{1} = opt_catProps(props, acq_getSubjectCode); 
  return;
end;

opt= opt_proplistToStruct(varargin{:});
[opt,isdefault] = opt_setDefaults(opt, props);
opt_checkProplist(opt, props);

%% Check whether a directory exists that is to be used
dd= dir([BBCI.RawDir 'VP???_' today_str '*']);

if ~opt.multiple_folders & length(dd)>1,
  error('multiple folder of today exist, but opt.multiple_folder is set to 0.');
end

k= 0;

while isempty(BBCI.Tp.Code) & k<length(dd),
  k= k+1;
  de= dir([BBCI.RawDir dd(k).name '\*.eeg']);
  if ~opt.multiple_folders | isempty(de),
    is= find(dd(k).name=='_', 1, 'first');
    BBCI.Tp.Code= dd(k).name(1:is-1);
    fprintf('!!Using existing directory <%s>!!\n', dd(k).name);
  end
end

% if BBCI.Tp.Code is empty, we generate a new one
if(isempty(BBCI.Tp.Code)),
    BBCI.Tp.Code= acq_getSubjectCode('prefix_letter', BBCI.Acq.Prefix, ...
                                     'letter_start', BBCI.Acq.StartLetter);
end;

BBCI.Tp.Dir= [BBCI.RawDir BBCI.Tp.Code '_' today_str filesep];

if ~exist(BBCI.Tp.Dir, 'dir'),
  mkdir_rec(BBCI.Tp.Dir);
end

fprintf('EEG data will be saved in <%s>.\n', BBCI.Tp.Dir);
