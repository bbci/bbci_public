function marker = stimutil_waitForMarker(bbci)
%STIMUTIL_WAITFORMARKER - Wait until specified marker is received
%
%Synopsis:
% stimutil_waitForMarker(BBCI)
% 
%Arguments:
% BBCI: struct as in bbci_apply. Here, only bbci.source and
%    bbci.quit_condition.marker matter


if nargin==0,
	marker= {'XXX', [], 'int'};
	return;
end

misc_checkType(bbci, 'STRUCT(source)');

bbci= bbci_apply_setDefaults(bbci);
bbci.source.record_signals= 0;
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
