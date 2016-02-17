function acq_checkTriggers(bbci)
%ACQ_CHECKTRIGGERS - Check whether triggers are operational
%
%Synopsis:
% acq_checkTriggers(<BBCI>)
%
%If no BBCI structure is specified, the default bbci.source is assumed
%which is (currently) BrainVision.


misc_checkTypeIfExists('bbci', 'STRUCT');

bbci= bbci_apply_setDefaults(bbci);
bbci.source.record_signals= 0;
[data, bbci]= bbci_apply_initData(bbci);
pause(0.5);

inp= 2.^[0:7];
trigger_ok= 1;
for k= 1:length(inp),
  fprintf('sending trigger: %3d -> received: ', inp(k));
  outp{k}= acq_checkTrigger(bbci, data, inp(k), 500);
  if isempty(outp{k}),
    fprintf('nothing.\n');
  else
    fprintf('%3d.\n', outp{k});
  end
  if ~isequal(inp(k), outp{k}),
    trigger_ok= 0;
  end
end

bbci_apply_close(bbci);
if trigger_ok,
  fprintf('Trigger test successful.\n');
else
  error('!!! Trigger test unsuccessful !!!\n');
end
return


function outp= acq_checkTrigger(bbci, data, inp, timeout)

outp= [];
trigger_received= false;
t0= clock;
bbci_trigger(bbci, inp);
while isempty(outp) && etime(clock, t0)*1000<timeout,
  [source, marker]= ...
        bbci_apply_acquireData(data.source, bbci.source, data.marker);
  if ~source.state.running,
    break;
  end
  if length(marker.desc)>1,
    outp= marker.desc(end);
  end
end
