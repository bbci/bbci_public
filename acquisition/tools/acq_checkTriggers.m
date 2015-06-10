function acq_checkTriggers(bbci)
%ACQ_CHECKTRIGGERS - Check whether triggers are operational
%
%Synopsis:
% acq_checkTriggers(<BBCI>)
%
%If no BBCI structure is specified, the default bbci.source is assumed
%which is (currently) BrainVision.

% misc_checkTypeIfExists('bbci', 'STRUCT');
% The above function will never throw an error!
misc_checkType(bbci, 'STRUCT'); % Changed version

bbci= bbci_apply_setDefaults(bbci);
bbci.source.record_signals= 0;
[data, bbci]= bbci_apply_initData(bbci);

inp= 2.^(0:7); % FIXED: pointwise power
trigger_ok= 1;
for k= 1:8,
  fprintf('sending trigger: %3d -> received: ', inp(k));
  outp= acq_checkTrigger(bbci, data, inp(k), 500); % FIXED: pass 'data'
  if isempty(outp), % CHANGED: 'outp' is no longer a cell array
    fprintf('nothing.\n');
  else
    fprintf('%3d.\n', outp); % FIXED: missing argument for %3d
  end
  if ~isequal(inp(k), outp),
    trigger_ok= 0;
  end
end

if trigger_ok,
  fprintf('Trigger test successful.\n');
else
  error('!!! Trigger test unsuccessful !!!\n');
end
bbci_apply_close(bbci); % FIXED: line moved from acq_checkTrigger
return


function outp= acq_checkTrigger(bbci, data, inp, timeout) % FIXED: args

outp= [];
bbci_trigger(bbci,inp); % FIXED: added this line to actually send marker
t0= clock;
while isempty(outp) && etime(clock, t0)*1000<timeout,
  [source, marker]= ...
        bbci_apply_acquireData(data.source, bbci.source, data.marker);
  if ~source.state.running,
    break;
  end
  outp= marker.desc;
end
if size(outp) > 0,
    outp=outp(end); % FIXED: some marker.desc are arrays
end