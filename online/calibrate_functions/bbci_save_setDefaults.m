function bbci= bbci_save_setDefaults(bbci, prop_defaults)
%BBCI_SAVE_SETDEFAULTS - Set default values in bbci for bbci_calibrate
%
%Synopsis:
%  BBCI= bbci_save_setDefaults
%  BBCI= bbci_save_setDefaults(BBCI, <PROPDEFAULTS>)
%
%Arguments:
%  BBCI - Structure of bbci_calibrate which specifies in its subfield
%      'save' how the BBCI classifier is saved.
%      This function is mainly used internally, but might also in some
%      case be useful in scripts.
%  'PROPDEFAULTS' - Property list of additional default properties/values
%      which override the default properties of this function, but not
%      existing fields in BBCI.
%
%Output:
%  BBCI - Updated bbci structure
%
%Example:
%  bbci= bbci_save_setDefaults('file', 'SIC_Lap_C34_bp2_LR');
%  bbci_prettyPrint(bbci);

% 01-2012 Benjamin Blankertz


global BTB

if nargin==0,
  bbci= [];
  prop_defaults= {};
elseif nargin==1,
  if iscell(bbci),
    prop_defaults= bbci;
    bbci= [];
  else
    prop_defaults= {};
  end
end

bbci= opt_setDefaults(bbci, {'calibrate'   struct   'STRUCT'});

bbci.calibrate= opt_setDefaults(bbci.calibrate, {'save'  struct  'STRUCT'});

if isfield(bbci.calibrate, 'folder'),
  default_save_folder= bbci.calibrate.folder;
else
  default_save_folder= BTB.Tp.Dir;
end

props= {'file'          'bbci_classifier'      'CHAR'
        'folder'        default_save_folder    'CHAR'
        'overwrite'     1                      '!BOOL'
        'raw_data'      0                      '!BOOL'
        'data'          'separately'           'CHAR(separately combined)'
        'figures'       0                      '!BOOL'
        'figures_spec'  {'paperSize','auto'}   'PROPLIST'
       };
for k= 1:size(prop_defaults,1),
  idx= strmatch(prop_defaults{k,1}, props(:,1), 'exact');
  props(idx,1:2)= prop_defaults(k,1:2);
end

bbci.calibrate.save= opt_setDefaults('bbci.calibrate.save', props);
if fileutil_isAbsolutePath(bbci.calibrate.save.file),
  bbci.calibrate.save.folder= '';
end

% Force a clean division into folder name and file name:
[pat,file]= fileparts(bbci.calibrate.save.file);
if ~isempty(pat),
  bbci.calibrate.save.folder= strcat(bbci.calibrate.save.folder, pat);
  bbci.calibrate.save.file= file;
end
