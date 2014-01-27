function out= bvr_startrecording(filebase, varargin)
%BVR_STARTRECORDING - Start Acquisition with BV RECORDER
%
% The actual filename for recording is composed of BBCI.Tp.Dir (global
% variable BBCI), a given basename, and optionally the VP-CODE (BBCI.Tp.Code).
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
%   'AppendTpCode': BOOL: Append the BBCI.Tp.Code (global variable) to file name
%
%Returns:
% FILENAME: Actually chosen filename
%
%Uses global variable
% BBCI - Substruct Tp

global BBCI

props= {'Impedances'    1   'BOOL'
        'AppendTpCode'  1   'BOOL'
       };

if isempty(BBCI.Tp.Dir),
  error('global BBCI.Tp.Dir needs to be set');
end

misc_checkType(filebase, 'CHAR');

opt= opt_proplistToStruct(varargin{:});
[opt, isdefault]= opt_setDefaults(opt, props);
opt_checkProplist(opt, props);

                
%% in case recording is still running, stop it
bvr_sendcommand('stoprecording');

if opt.AppendTpCode,
  filebase= [filebase BBCI.Tp.Code];
end

num= 1;
file= [BBCI.Tp.Dir '\' filebase];
[file '.eeg']
while exist([file '.eeg'], 'file'),
  num= num + 1;
  file= sprintf('%s%s%02d', BBCI.Tp.Dir, filebase, num);
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
