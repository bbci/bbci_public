function [ running ] = check_lsl_connection(inlet_struct)
%CHECK_LSL_CONNECTION Checks the connection to the lsl library
%   gets lsl library object and returns true if both, eeg and markers
%   stream are availabel. Return false otherwise. 

result_eeg = inlet_struct.x.pull_sample(); 
result_mrk = inlet_struct.mrk.pull_sample(); 

running = ~(isempty(result_eeg) | isempty(result_mrk));
end

