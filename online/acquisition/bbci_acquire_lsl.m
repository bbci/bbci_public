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
if isequal(varargin{1}, 'init'),
  state= opt_proplistToStruct(varargin{2:end});
  default_clab= ...
    {'AF5' 'AF3' 'AF1' 'AFz' 'AF2' 'AF4' 'AF6' ...
     'F5' 'F3', 'F1' 'Fz' 'F2' 'F4' 'F6' ...
     'FC7' 'FC5' 'FC3' 'FC1' 'FCz' 'FC2' 'FC4' 'FC6' 'FC8' ...
     'T7' 'C5' 'C3' 'C1' 'Cz' 'C2' 'C4' 'C6' 'T8' ...
     'CP7' 'CP5' 'CP3' 'CP1' 'CPz' 'CP2' 'CP4' 'CP6' 'CP8' ...
     'P7' 'P5' 'P3' 'P1' 'Pz' 'P2' 'P4' 'P6' 'P8' ...
     'PO5' 'PO3' 'PO1' 'POz' 'PO2' 'PO4' 'PO6' ...
     'O5' 'O3' 'O1' 'Oz' 'O2' 'O4' 'O6' ...
    };
  props= {'fs'            250            '!DOUBLE[1]'
          'clab'          default_clab   'CELL{CHAR}'
          'blocksize'     40             '!DOUBLE[1]'
          'port'          'COM11'        '!CHAR'
          'timeout'       3              '!DOUBLE[1]'
          'filtHd'        []             'STRUCT'
          'verbose'       true           '!BOOL'
         };
  [state, isdefault]= opt_setDefaults(state, props, 1);
  if state.fs~=250,
    error('Only fs=250 allowed');
  end
  if isdefault.filtHd,
    % Fs/4
    filt1.b= [0.85 0 0.85];
    filt1.a= [1 0 0.7];
    %Fs/2
    filt2.b= [0.8 0.8];
    filt2.a= [1 0.6];
    state.filtHd= procutil_catFilters(filt1, filt2);
    state.filtHd.PersistentMemory= true;
  end
  state.nChans= length(state.clab);
  state.nBytesPerPacket= 2+3*state.nChans+4;
  nPacketsPerPoll= ceil(state.blocksize/1000*state.fs);
  state.nBytesPerPoll= nPacketsPerPoll*state.nBytesPerPacket;
  
  % resolve eeg stream:
  eeg = {};
  state.lib = lsl_loadlib();
  for i=1:5
      eeg = lsl_resolve_byprop(state.lib,'type','EEG'); 
      if ~isempty(eeg) 
          break
      end
      pause(0.05)
  end
  if isempty(eeg)
      error('No LSL EEG stream on the network')
  end
  mrks = {}; 
  % resolve marker stream, try several times 
  for i=1:5
      mrks = lsl_resolve_byprop(state.lib,'type','Markers'); 
      if ~isempty(mrks)
          break
      end
      pause(0.05)
  end
  if isempty(mrks)
      error('No LSL marker stream on the network')
  end
  
  % create a new inlet
  disp('Opening an inlet...');
  state.inlet.x = lsl_inlet(eeg{1});
  state.inlet.mrk = lsl_inlet(mrks{1});
  
  state.packetNo=[];  
  state.buffer= [];
  state.lastx= zeros(1, state.nChans);
  state.lastMrkDesc= 256;
  state.scale= 1000000/2^24;
  if isempty(state.filtHd),
    reset(state.filtHd);
  end
  output= {state};
elseif isequal(varargin{1}, 'close'),
   % close LSL inlets?
  output= {};
  
elseif length(varargin)~=1,
  error('Except for INIT/CLOSE case, only one input argument expected');
else
  if ~isstruct(varargin{1}),
    error('First input argument must be ''init'', ''close'', or a struct');
  end
  state= varargin{1};
  
  % check whether streams are still on
  state.running = check_lsl_connection(state.inlet); 

  % get data chunk from the inlet
  [cntx,stamps_eeg] = state.inlet.x.pull_sample();
  % get markers
  [mrkDesc,mrkTime] = state.inlet.mrk.pull_sample();
  % reshape cntx to time x channels
  cntx = cntx';
  % save last marker
  state.lastMrkDesc= mrkDesc(end);
  % save last sample
  state.lastx= cntx(end,:);
  
  % Apply filter if requested (dfilt.filter automatically saves the state)
  if ~isempty(state.filtHd),
    cntx= filter(state.filtHd, cntx, 1);
  end
  
  output = {cntx, mrkTime, mrkDesc, state};
end
varargout= output(1:nargout);
