function [] = bbci_trigger_lsl( value, outlet )
%BBCI_TRIGGER_LSL sends trigger using LabStreamingLayer
%   Sends trigger using the marker stream outlet defined in the
%   labstreaminglayer. 
% value     trigger value, string
% outlet    labstreaming layer marker stream outlet

outlet.push_sample({value});

end

