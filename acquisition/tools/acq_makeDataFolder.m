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


props = {'MultipleFolders'	0   'BOOL'
         'Interactive'      1   'BOOL'};

% if nargin==0,
%   varargout{1} = opt_catProps(props, acq_getSubjectCode); 
%   return;
% end;

opt= opt_proplistToStruct(varargin{:});
[opt,isdefault] = opt_setDefaults(opt, props);
opt_checkProplist(opt, props);

%% Check whether a directory exists that is to be used
dd= dir([BTB.RawDir 'VP???_' today_str '*']);

FolderList{1}= strcat('Temp_', today_str);
Comment{1}= 'for testing purpose';
NewCode= acq_getSubjectCode;
FolderList{2}= strcat(NewCode, '_', today_str);
Comment{2}= 'to be generated as new folder';
for k= 1:length(dd),
  FolderList{2+k}= dd(k).name;
  de= dir([BTB.RawDir dd(k).name '\*']);
  deeg= dir([BTB.RawDir dd(k).name '\*.eeg']);
  if length(de)<=2,
    Comment{2+k}= 'empty folder';
  elseif isempty(deeg),
    Comment{2+k}= 'folder without *.eeg files';
  else
    Comment{2+k}= 'folder with *.eeg files';
  end
end

if opt.Interactive,
  for k= 1:length(FolderList),
    fprintf('(%d) %s  (%s)\n', k, FolderList{k}, Comment{k});
  end
  choice= 0;
  while choice<1 || choice>length(FolderList),
    msg= sprintf(' -> Input your choice (1-%d): ', length(FolderList));
    choice= input(msg);
    if isempty(choice),
      choice= 1;
    end
  end
else
  choice= 2;
end
BTB.Tp.Dir= fullfile(BTB.RawDir, FolderList{choice});
is= find(FolderList{choice}=='_', 1, 'first');
BTB.Tp.Code= FolderList{choice}(1:is-1);

if ~exist(BTB.Tp.Dir, 'dir'),
  mkdir(BTB.Tp.Dir);
end

fprintf('EEG data will be saved in <%s>.\n', BTB.Tp.Dir);
