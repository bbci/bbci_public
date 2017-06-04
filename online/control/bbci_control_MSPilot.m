function [packet, state]= bbci_control_MSPilot(cfy_out, state, event, opt)
%BBCI_CONTROL_MSPILOT Generate control signal for MindSee Pilot study
% 
%Synopsis:
%  [PACKET, STATE]= bbci_control_XYZ(CFY_OUT, STATE, EVENT_INFO, <PARAMS>)
%
%Arguments:
%  CFY_OUT - Output of the classifier
%  STATE - Internal state variable, which is empty in the first call of a
%      run of bbci_apply.
%  EVENT_INFO - Structure that specifies the event (fields 'time' and 'desc')
%      that triggered the evaluation of this control. Furthermore, EVENT_INFO
%      contains the whole marker queue in the field 'all_markers'.
%  PARAMS - Additional parameters that can be specified in bbci.control.param
%      are passed as further arguments.
%
%Output:
% PACKET: Variable/value list in a CELL defining the control signal that
%     is to be sent via UDP to the application.
% STATE: Updated internal state variable
%
% 02-2016 Jan Boelts

% check whether there is eyetracker data
if isfield(opt, 'fixx') && isfield(opt, 'fixy')
    packet = {['x ' num2str(opt.fixx) ' y ' num2str(opt.fixy) ' cfy_out ' num2str(cfy_out)]}; 
else
    packet = {'cfy_out', cfy_out}; 
end
end

