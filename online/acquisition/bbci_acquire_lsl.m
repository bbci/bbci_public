function varargout= bbci_acquire_lsl(varargin)
%BBCI_ACQUIRE_lsl - Online data acquisition from labstreaming layer (LSL)
%   This function acquires small blocks of signals including meta
%   information from the LSL. The LSL can hold streams from any common 
%   devices that will be accessed by type: 'eeg' or 'marker'. For details
%   see https://code.google.com/p/labstreaminglayer/. 
%
%Synopsis:
%  STATE= bbci_acquire_XYZ('init', <PARAM>)
%  [CNTX, MRKTIME, MRKDESC, STATE]= bbci_acquire_XYZ(STATE)
%  bbci_acquire_XYZ('close')
%  bbci_acquire_XYZ('close', STATE)
% 
%Arguments:
%  PARAM - Optional arguments, specific to XYZ.
%  
%Output:
%  STATE - Structure characterizing the incoming signals; fields:
%     'fs', 'clab', and intern stuff
%  CNTX - 'acquired' signals [Time x Channels]
%  The following variables hold the markers that have been 'acquired' within
%  the current block (if any).
%  MRKTIME - DOUBLE: [1 nMarkers] position [msec] within data block.
%      A marker occurrence within the first sample would give
%      MARTIME= 1/STATE.fs.
%  MRKDESC - CELL {1 nMarkers} descriptors like 'S 52'
% --- --- --- ---

output= {cntx, mrkTime, mrkDesc(iNonvoid), state};
varargout= output(1:nargout);
end