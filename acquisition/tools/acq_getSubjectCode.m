function subject_code = acq_getSubjectCode(varargin)
%GET_SUBJECT_CODE - Gets a new subject code
% 
%Synopsis:
% folder= get_subject_code(OPT);
%
%Arguments:
% OPT: struct or property/value list of optinal properties:
%
%Returns:
% subject_code
%
%Example:
% getSubjectCode('code_prefix', 'subject_')
% 06-12 Javier Pascual. From code from acq_makeDataFolder


global BBCI

props = {   'code_prefix'       'VP'    'CHAR'
            'prefix_letter'     'a'     'CHAR'
            'letter_start'      'a'     'CHAR'
            'log_dir'           0       'BOOL'};

if nargin==0,
    subject_code = props; 
    return;
end;
  
%% Get the date
today_vec= clock;
today_str= sprintf('%02d_%02d_%02d', today_vec(1)-2000, today_vec(2:3));

opt= opt_proplistToStruct(varargin{:});
[opt,isdefault] = opt_setDefaults(opt, props);
opt_checkProplist(opt, props);


subject_code = [];

%% Generate a Subject Code and folder name to save the EEG data in
while isempty(subject_code),
  dd= dir([BBCI.RawDir opt.code_prefix opt.prefix_letter opt.letter_start '*']);
  if isempty(dd),
    subject_code = [opt.code_prefix opt.prefix_letter opt.letter_start 'a'];
    continue;
  end

  is= find(dd(end).name=='_', 1, 'first');
  last_letter= dd(end).name(is-1);
  if last_letter=='z',
    opt.letter_start= char(opt.letter_start+1);
    last_letter= 'a'-1;
  end;
  subject_code = [opt.code_prefix opt.prefix_letter opt.letter_start ...
                  char(last_letter+1)];
end;
