function bbci= bbci_calibrate_setDefaults(bbci)
%BBCI_CALIBRATE_SETDEFAULTS - Set default values in bbci for bbci_calibrate
%
%Synopsis:
%  BBCI= bbci_calibrate_setDefaults
%  BBCI= bbci_calibrate_setDefaults(BBCI)
%
%Arguments:
%  BBCI - Structure of bbci_calibrate which specifies calibration data
%      and methods to determine parameters of feature extraction and
%      classification, type 'help bbci_calibrate_structures' for detailed
%      information about the fields of this structure.
%
%Output:
%  BBCI - Updated bbci structure

% 09-2011 Benjamin Blankertz


global BTB

if nargin==0,
  bbci= [];
end

bbci= opt_setDefaults(bbci, {'calibrate'   struct   'STRUCT'});

props= {'folder'          BTB.Tp.Dir                   'CHAR'
        'file'            ''                           '!CELL|!CHAR'
        'read_fcn'        @file_readBV                 '!FUNC'
        'read_param'      {}                           'CELL'
        'marker_fcn'      []                           'FUNC'
        'marker_param'    {}                           'CELL'
        'montage_fcn'     @mnt_setElectrodePositions   'FUNC'
        'montage_param'   {}                           'CELL'
        'fcn'             []                           'FUNC'
        'settings'        struct                       'STRUCT'
        'default_settings'   struct                    'STRUCT'
        'log'             struct                       'STRUCT'
        'save'            struct                       'STRUCT'
       };
bbci.calibrate= opt_setDefaults('bbci.calibrate', props);

default_save_file= 'bbci_classifier';
default_log_file= 'bbci_calibrate_log';
if ~isempty(bbci.calibrate.fcn),
  appendix= strrep(func2str(bbci.calibrate.fcn), 'bbci_calibrate', '');
  default_save_file= [default_save_file appendix];
  default_log_file= [default_log_file appendix];
end
prop_defaults= {'folder'  bbci.calibrate.folder   'CHAR'
                'file'    default_save_file       'CHAR'};
bbci= bbci_save_setDefaults(bbci, prop_defaults);

props= {'output'  'screen&file'           'BOOL|CHAR(screen file screen&file)'
        'folder'   bbci.calibrate.folder  'CHAR'
        'file'     default_log_file       'CHAR'
        'force_overwriting'   0           '!BOOL'
       };
bbci.calibrate.log= opt_setDefaults('bbci.calibrate.log', props);
