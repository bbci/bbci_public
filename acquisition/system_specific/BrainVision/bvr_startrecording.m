function out= bvr_startrecording(filebase, varargin)
%BVR_STARTRECORDING - Start Acquisition with BV RECORDER
%
% The actual filename for recording is composed of BTB.Tp.Dir (global
% variable BTB), a given basename, and optionally the VP-CODE (BTB.Tp.Code).
% The a file of that name exists a counter is increased and the
% corresponding nummber is appended, until a new filename was created.
%
%Synopsis:
% FILENAME= bvr_startrecording(FILEBASE, <OPT>)
%
%Arguments:
% FILEBASE: basename for the EEG files.
% OPT: Struct or property/value list of optional properties:
%   'Impedances': BOOL: start impedance measurement at the beginning
%   'AppendTpCode': BOOL: Append the BTB.Tp.Code (global variable) to file name
%
%Returns:
% FILENAME: Actually chosen filename
%
%Uses global variable
% BTB - Substruct Tp

global BTB

props= {'Impedances'    0   'BOOL'
        'AppendTpCode'  1   'BOOL'
       };

if isempty(BTB.Tp.Dir),
  error('global BTB.Tp.Dir needs to be set');
end

misc_checkType(filebase, 'CHAR');

opt= opt_proplistToStruct(varargin{:});
[opt, isdefault]= opt_setDefaults(opt, props);
opt_checkProplist(opt, props);

                
% in case recording is still running, stop it
bvr_sendcommand('stoprecording');

if opt.AppendTpCode,
  filebase= [filebase BTB.Tp.Code];
end

num= 1;
file= fullfile(BTB.Tp.Dir, filebase);
while exist([file '.eeg'], 'file'),
  num= num + 1;
  file= fullfile(BTB.Tp.Dir, sprintf('%s%02d', filebase, num));
end

if opt.Impedances,
  bvr_sendcommand('startimprecording', [file '.eeg']);
else
  bvr_sendcommand('startrecording', [file '.eeg']);
end
fprintf('Saving to <%s>.\n', file);

if nargout>0,
  out= file;
end
