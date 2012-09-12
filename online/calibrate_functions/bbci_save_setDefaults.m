function bbci= bbci_save_setDefaults(varargin)
%BBCI_SAVE_SETDEFAULTS - Set default values in bbci for bbci_calibrate
%
%Synopsis:
%  BBCI= bbci_save_setDefaults
%  BBCI= bbci_save_setDefaults(BBCI)
%  BBCI= bbci_save_setDefaults('Param1',VALUE1, ...)
%  BBCI= bbci_save_setDefaults(BBCI, 'Param1',VALUE1, ...)
%
%Arguments:
%  BBCI - Structure of bbci_calibrate which specifies in its subfield
%      'save' how the BBCI classifier is saved.
%      This function is mainly used internally, but might also in some
%      case be useful in scripts.
%  'Param1', VALUE1, ... - Parameter/value list of properties to be set
%      in bbci.calibrate.save
%
%Output:
%  BBCI - Updated bbci structure
%
%Example:
%  bbci= bbci_save_setDefaults('file', 'SIC_Lap_C34_bp2_LR');
%  bbci_prettyPrint(bbci);

% 01-2012 Benjamin Blankertz


global BBCI

bbci= [];
if nargin>0 && (isstruct(varargin{1}) || isempty(varargin{1})),
  bbci= varargin{1};
  varargin(1)= [];
end

bbci= opt_setDefaults(bbci, {'calibrate'   struct   'STRUCT'});

bbci.calibrate= opt_setDefaults(bbci.calibrate, {'save'  struct  'STRUCT'});
bbci.calibrate.save= struct_copyFields(bbci.calibrate.save, ...
                                       struct(varargin{:}));

if isfield(bbci.calibrate, 'folder'),
  default_save_folder= bbci.calibrate.folder;
else
  default_save_folder= BBCI.Tp.Dir;
end

props= {'file'   'bbci_classifier'    'CHAR'
        'folder'        default_save_folder    'CHAR'
        'overwrite'     1                      '!BOOL'
        'raw_data'      0                      '!BOOL'
        'data'          'separately'           'CHAR(separately combined)'
        'figures'       0                      '!BOOL'
        'figures_spec'  {'paperSize','auto'}   'PROPLIST'
       };
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
