function data= bbci_recordSignals(bbci_in, filename)
%BBCI_RECORDSIGNALS - Record acquired brain signals
%
%Synopsis:
%  DATA= bbci_recordSignals(BBCI, BASENAME)
%
%Arguments:
%  BBCI: Type 'help bbci_apply_structures' to get a description of the 
%        structure 'bbci'. This function only uses the fields
%        'source': while defines the data acquisition, and
%        'quit_condition'
%  BASENAME: Basename of the files. Nummers are appended in order to avoid
%        overwriting.

if nargin<2,
    filename= '/tmp/bbci_recording';
end

bbci= struct_copyFields(bbci_in, {'source','quit_condition'});
bbci.feature.ival= [-100 0];

%default_param= {'internal',1, 'precision','double'};
default_param= {'internal',1};
props= {'record_signals'    1               'BOOL',
        'record_basename'   filename        'CHAR',
        'record_param'      default_param   'PROPLIST'};
bbci.source= opt_setDefaults(bbci.source, props);
bbci.source.record_basename= filename;

fprintf('Recording started.\n');

bbci= bbci_apply_setDefaults(bbci);
[data, bbci]= bbci_apply_initData(bbci);
run= true;
while run,
  [data.source, data.marker]= ...
        bbci_apply_acquireData(data.source, bbci.source, data.marker);
  if ~data.source.state.running,
    break;
  end
  data.marker.current_time= data.source.time;
  run= bbci_apply_evalQuitCondition(data.marker, bbci);
end
bbci_apply_close(bbci, data);

fprintf('Recording finished -> %s\n', data.source.record.filename);
