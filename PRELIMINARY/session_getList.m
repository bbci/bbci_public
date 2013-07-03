function varargout = session_getList(sessionName, varargin)
%GET_SESSION_LIST - Get List of folder names of a particular study
% *** This version works with the new toolbox ***!
%
%Synopsis:
% [SBJ,SESSION] = get_sessionList(SESSION_NAME, <OPT>)
%
%Arguments:
% SESSION_NAME: Name of a session, typically a subfolder of [BCI_DIR
%   'investigate']. For subfolders in 'studies', the parent folder can be left
%   out, e.g. you can use 'season9' instead of 'studies/season9'.  If
%   SESSION_NAME is empty or left out, SESSION_LIST is either extracted from
%   the working directory, or, from the TODAY_DIR, if a global variable of
%   that name exists (expection, see below).
%
%   The session_list file itself can also contain shell-like comments, so that
%   text behind a "#" character on a line is ignored. This is quite handy if
%   you need to comment out certain sessions.
%       
% OPT: struct or property/value list of optional arguments: 
% 'checkTpDir': If the global variable BBCI.Tp.Dir ist not empty, .
% 'Filename'       : name of the session list file, default 'session_list'
%
%Returns:
% SBJ:      Struct array with subject information.
% SESSION:  Folder for the scripts
%
%Examples:
% get_session_list('season9');
% get_session_list('studies/season9');
% get_session_list('projects/projekt_treder09');
% cd([BCI_DIR 'studies/carrace_season1']);
% get_session_list
% global TODAY_DIR
% TODAY_DIR= 'VPgab_09_08_21';
% get_session_list
% get_session_list('', 'check_TODAY_DIR', 0);
% TODAY_DIR= '/home/bbci/data/bbciRaw//VPgab_09_08_21/';
% get_session_list

global BBCI

props = {'CheckTpDir'       1,                  '!BOOL';
         'DetailFile',    	'session_details',  '!CHAR';
         'Filename',        'session_list',     '!CHAR';
         };

if nargin==0,
  varargout= props; return
end

opt= opt_proplistToStruct(varargin{:});
[opt,isdefault] = opt_setDefaults(opt, props);
opt_checkProplist(opt, props);

misc_checkType(sessionName,'CHAR');


if opt.CheckTpDir,
  if ~isempty(BBCI.Tp.Dir),
    subdir= BBCI.Tp.Dir;
    while ismember(subdir(end), '/\'),
      subdir(end)= [];
    end
    [dmy, subdir]= fileparts(subdir);
    subdir_list= {subdir};
    if nargout>1,
      sessionName= get_sessionName(sessionName);
    end
    varargout{1} = subdir_list;
    varargout{2} = sessionName;
    return;
  end
end

if nargin==0,
  sessionName= '';
end

sessionName= get_sessionName(sessionName);

if fileutil_isAbsolutePath(sessionName)
  full_path= [sessionName filesep];  
else
  full_path = [BBCI.InvestigationDir sessionName filesep];
end

subdir_list= textread([full_path opt.Filename], '%s', 'commentstyle', 'shell');

lab = [];dat = [];
if exist([full_path opt.DetailFile], 'file')
    [lab dat] = get_sessionDetails([full_path opt.DetailFile]);
end
name = arrayfun(@(s) s{1}(1:find(s{1}=='_',1,'first')-1),subdir_list,'UniformOutput',0);
expid = arrayfun(@(s) strrep(s{1}, '_', ''),subdir_list,'UniformOutput',0);
  
%% Assign outputs
sbj = struct();
for ii=1:length(subdir_list)
  sbj(ii).subdir = subdir_list{ii};
  sbj(ii).name = name{ii};
  sbj(ii).shortname = name{ii}(3:end);  % name without "VP"
  sbj(ii).expid = expid{ii};
  sbj(ii).num = ii;
end
sbj = merge_sbj_with_details(sbj, lab, dat);
varargout{1} = sbj;
varargout{2} = sessionName;


end

function sbj = merge_sbj_with_details(sbj, lab, dat),

    sid = [];
    
    if isempty(dat) || isempty(lab),
        return;
    elseif strcmp(lab{1}, 'id')
        sid = {sbj.subdir};
    elseif length(sbj) ~= size(dat{1}, 1),
        error('No id set in detail file AND number of lines in session_list and session_details differ.');
    end

    for ii = 1:length(sbj),
        cur_i = ii;
        if ~isempty(sid),
            cur_i = strmatch(sid(ii), dat{1}, 'exact');
        end
        
        for jj = 1:length(lab),
            if ~strcmp(lab{jj}, 'id'),
                sbj(ii).(lab{jj}) = dat{jj}(ii);
                if iscell(sbj(ii).(lab{jj})),
                    sbj(ii).(lab{jj}) = sbj(ii).(lab{jj}){1};
                end
            end
        end
    end
end
