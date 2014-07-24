function marker = stimutil_waitForMarker(bbci, quit_marker)
%STIMUTIL_WAITFORMARKER - Wait until specified marker is received
%
%Synopsis:
% stimutil_waitForMarker(BBCI, <QUIT_MARKER>)
% stimutil_waitForMarker(QUIT_MARKER)
% 
%Arguments:
% BBCI: struct as in bbci_apply. Here, only bbci.source and
%    bbci.quit_condition.marker matter
% QUIT_MARKER: DOUBLE[1 nMarkers], These will override 
%    bbci.quit_condition.marker
%
%If no BBCI structure is specified, the default bbci.source is assumed
%which is (currently) BrainVision.

if nargin==1,
  if isnumeric(bbci),
    quit_marker= bbci;
    bbci= [];
  end
end
misc_checkTypeIfExists('bbci', 'STRUCT');
misc_checkTypeIfExists('quit_marker', 'INT');

if exist('quit_marker', 'var'),
  bbci.quit_condition.marker= quit_marker;
end

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
