function subject_code = acq_getSubjectCode(varargin)
%GET_SUBJECT_CODE - Gets a new subject code
% 
%Synopsis:
% TPCODE= acq_getSubjectCode(<OPT>);
%
%Arguments:
% OPT: struct or property/value list of optinal properties:
%    'CodePrefix'    [CHAR], default 'VP
%    'PrefixLetter'  [CHAR], default BTB.Acq.Prefix
%    'StartLetter'   [CHAR], default BTB.Acq.StartLetter
%
%Returns:
% TPCODE
%
%Example:
% TPCode= acq_getSubjectCode('CodePrefix', 'S_')
% 06-12 Javier Pascual. From code from acq_makeDataFolder


global BTB

props= {'CodePrefix'     'VP'                  'CHAR'
        'PrefixLetter'   BTB.Acq.Prefix        'CHAR'
        'LetterStart'    BTB.Acq.StartLetter   'CHAR'
       };

%if nargin==0,
%  subject_code = props; 
%  return;
%end;
  
%% Get the date
today_vec= clock;
today_str= sprintf('%02d_%02d_%02d', today_vec(1)-2000, today_vec(2:3));

opt= opt_proplistToStruct(varargin{:});
[opt,isdefault] = opt_setDefaults(opt, props);
opt_checkProplist(opt, props);


subject_code = [];

%% Generate a Subject Code and folder name to save the EEG data in
while isempty(subject_code),
  dd= dir([BTB.RawDir opt.CodePrefix opt.PrefixLetter opt.LetterStart '*']);
  if isempty(dd),
    subject_code = [opt.CodePrefix opt.PrefixLetter opt.LetterStart 'a'];
    continue;
  end

  is= find(dd(end).name=='_', 1, 'first');
  last_letter= dd(end).name(is-1);
  if last_letter=='z',
    opt.LetterStart= char(opt.LetterStart+1);
    last_letter= 'a'-1;
	else
    subject_code= [opt.CodePrefix opt.PrefixLetter opt.LetterStart ...
                   char(last_letter+1)];
	end
end
