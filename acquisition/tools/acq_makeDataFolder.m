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
% Set global variables BTB.Tp.Code, BTB.Tp.Dir
%
% XX-XX Benjamin Blankertz 
% 06-12 Javier Pascual. Updated. Created new function getSubjectcode


global BTB

%BTB.Tp.Code = [];

%% Get the date
today_vec= clock;
today_str= sprintf('%02d_%02d_%02d', today_vec(1)-2000, today_vec(2:3));

if length(varargin)==1 && isequal(varargin{1},'tmp'),
  BTB.Tp.Dir= [BTB.RawDir 'Temp_' today_str '\'];
  if ~exist(BTB.Tp.Dir, 'dir'),
    mkdir_rec(BTB.Tp.Dir);
  end
  return;
end

if isempty(BTB.Acq.StartLetter),
  BTB.Acq.StartLetter= 'a';
end


props = {'MultipleFolders'	0	'BOOL'};

% if nargin==0,
%   varargout{1} = opt_catProps(props, acq_getSubjectCode); 
%   return;
% end;

opt= opt_proplistToStruct(varargin{:});
[opt,isdefault] = opt_setDefaults(opt, props);
opt_checkProplist(opt, props);

%% Check whether a directory exists that is to be used
dd= dir([BTB.RawDir 'VP???_' today_str '*']);

if ~opt.MultipleFolders && length(dd)>0,
  warning('multiple folder of today exist, but opt.MultipleFolder is set to false -> generating a new participant code.');
  BTB.Tp.Code= '';
else
  k= 0;
  while isempty(BTB.Tp.Code) && k<length(dd),
    k= k+1;
    de= dir([BTB.RawDir dd(k).name '\*.eeg']);
    if ~opt.MultipleFolders || isempty(de),
      is= find(dd(k).name=='_', 1, 'first');
      BTB.Tp.Code= dd(k).name(1:is-1);
      fprintf('!!Using existing directory <%s>!!\n', dd(k).name);
		end
  end
end

% if BTB.Tp.Code is empty, we generate a new one
if(isempty(BTB.Tp.Code)),
    BTB.Tp.Code= acq_getSubjectCode('PrefixLetter', BTB.Acq.Prefix, ...
                                     'LetterStart', BTB.Acq.StartLetter);
end;

BTB.Tp.Dir= [BTB.RawDir BTB.Tp.Code '_' today_str filesep];

if ~exist(BTB.Tp.Dir, 'dir'),
  mkdir(BTB.Tp.Dir);
end

fprintf('EEG data will be saved in <%s>.\n', BTB.Tp.Dir);
