function bbci_trigger_lsl(value, varargin)
%BBCI_TRIGGER_LSL Sends triggers using LabStreaminglayer
%   Sends trigger using the marker stream outlet defined in the
%   labstreaminglayer
% 
% value     trigger value, numeric
% varargin  the argument given bbci_trigger: either BBCI.trigger.param{:}
%           or BTB.Acq.TriggerParam{:}. In any case it should contain an 
%           LSL stream outlet of the marker stream 

if isnumeric(value)
    % hack to meet the format of the lsl marker stream and mimic the pp
    % marker format: 'S <markervalue>'
    marker = cat(2, 'S ', num2str(value));
    % push sample to marker stream outlet
   varargin{1}.push_sample({marker});
else
    warning('The trigger has to be numeric: no trigger was sent')
end
end

