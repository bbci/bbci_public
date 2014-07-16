function acq_checkTriggers(bbci)
%ACQ_CHECKTRIGGERS - Check whether triggers are operational
%
%Synopsis:
% acq_checkTriggers(<BBCI>)
%
%If no BBCI structure is specified, the default bbci.source is assumed
%which is (currently) BrainVision.


misc_checkTypeifExists('bbci', 'STRUCT');

bbci= bbci_apply_setDefaults(bbci);
bbci.source.record_signals= 0;
[data, bbci]= bbci_apply_initData(bbci);

inp= 2^[0:7];
trigger_ok= 1;
for k= 1:8,
  fprintf('sending trigger: %3d -> received: ', inp(k));
  outp{k}= acq_checkTrigger(bbci, inp(k), 500);
  if isempty(outp{k}),
    fprintf('nothing.\n');
  else
    fprintf('%3d.\n');
  end
  if ~isequal(inp(k), outp{k}),
    trigger_ok= 0;
  end
end

if trigger_ok,
  fprintf('Trigger test successful.\n');
else
  error('!!! Trigger test unsuccessful !!!\n');
end
return


function outp= acq_checkTrigger(bbci, inp, timeout)

outp= [];
trigger_received= false;
t0= clock;
while isempty(outp) && etime(clock, t0)*1000<timeout,
  [source, marker]= ...
        bbci_apply_acquireData(data.source, bbci.source, data.marker);
  if ~source.state.running,
    break;
  end
  outp= marker.desc;
end
bbci_apply_close(bbci);
