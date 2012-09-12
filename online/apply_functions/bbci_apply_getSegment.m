function epo= bbci_apply_getSegment(signal, reference_time, ival)
%BBCI_APPLY_GETSEGMENT - Retrieve segment of signals from buffer
%
%Synopsis:
%  EPO= bbci_apply_getSegment(SIGNAL, IVAL)
%
%Arguments:
%  SIGNAL - Structure buffering the continuous signals,
%      subfield of 'data' structure of bbci_apply
%  REFERENCE_TIME - Specifies the t=0 time point to which IVAL refers.
%      This is typically either the most recent time point (for continuous
%      classifcation), or the time point of an event marker.
%  IVAL - Time interval [start_msec end_msec] relative to the
%      REFERENCE_TIME that defines the segment within the continuous data.
%
%Output:
%  EPO - Structure of epoched signals with the fields
%        'x' (data matrix [time x channels]), 'clab', and 't' (time line).

% 02-2011 Benjamin Blankertz


% Determine the indices in the ring buffer that correspond to the specified
% time interval. There are rounding-issues here for some sampling rates.
% The following procedure should do ok.
si= 1000/signal.fs;
TIMEEPS= si/100;
len_sa= round(diff(ival)/si);
pos_zero= signal.ptr + ceil( (reference_time-signal.time-TIMEEPS)/si );
core_ival= [ceil(ival(1)/si) floor(ival(2)/si)];
addone= diff(core_ival)+1 < len_sa;
pos_end= pos_zero + floor(ival(2)/si) + addone;
idx= [-len_sa+1:0] + pos_end;
idx_ring= 1 + mod(idx-1, signal.size);

% Get requested segment from the ring buffer and store it into an EPO struct
epo.x= signal.x(idx_ring,:);
epo.clab= signal.clab;
timeival= si*(core_ival + [1 addone]);
timeival= round(10000*timeival)/10000;
epo.t= linspace(timeival(1), timeival(2), len_sa);
epo.fs= signal.fs;
