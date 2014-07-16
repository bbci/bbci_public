function varargout= bbci_acquire_cognionics(varargin)
%BBCI_ACQUIRE_cognionics - Online data acquisition from Cognionics headset
%
%Synopsis:
%  STATE= bbci_acquire_cognionics('init', <PARAM>)
%  [CNTX, MRKTIME, MRKDESC, STATE]= bbci_acquire_cognionics(STATE)
%  bbci_acquire_cognionics('close')
%  bbci_acquire_cognionics('close', STATE)
% 
%Arguments:
%  PARAM - Optional arguments
%    'clab', 'fs', 'filtHd', 'blocksize', 'port', 'timeout', 'verbose'
%  
%Output:
%  STATE - Structure characterizing the incoming signals; fields:
%     'fs', 'clab', and intern stuff
%  CNTX - 'acquired' signals [Time x Channels]
%    The following variables hold the markers that have been 'acquired' within
%    the current block (if any).
%  MRKTIME - DOUBLE: [1 nMarkers] position [msec] within data block.
%      A marker occurrence within the first sample would give
%      MRKTIME= 1/STATE.fs.
%  MRKDESC - DOUBLE [1 nMarkers] values of markers

% benjamin.blankertz


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
    filt1.b= [0.85 0 0.85]
    filt1.a= [1 0 0.7]
    %Fs/2
    filt2.b= [0.8 0.8]
    filt2.a= [1 0.6]
    state.filtHd= procutil_catFilters(filt1, filt2);
    state.filtHd.PersistentMemory= true;
  end
  state.nChans= length(state.clab);
  state.nBytesPerPacket= 2+3*state.nChans+4;
  nPacketsPerPoll= ceil(state.blocksize/1000*state.fs);
  state.nBytesPerPoll= nPacketsPerPoll*state.nBytesPerPacket;
  
  % try to find connected cognionics port
  cog_ports= instrfind('Tag', 'Cognionics');
  if isempty(cog_ports),
    state.sp= serial(state.port, 'BaudRate',115200, ...
                                 'Timeout',state.timeout, ...
                                 'Tag', 'Cognionics');
  elseif length(cog_ports)==1,
    state.sp= cog_ports;
    if strcmp(state.sp.Status, 'open'),
      fclose(state.sp);
    end
  else
    error('multiple ports connected to Cognioncs found');
  end
  state.sp.InputBufferSize= 5*state.nBytesPerPoll;
  
  fopen(state.sp);
  % Poll data several times to get into a more stable state
  for q= 1:3,
    fread(state.sp, state.sp.InputBufferSize, 'uint8');
  end
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
  cog_ports= instrfind('Tag', 'Cognionics');
  if ~isempty(cog_ports),
    fclose(cog_ports);
    %delete(cog_ports);  % shutdown port completely?
  end
  output= {};
elseif length(varargin)~=1,
  error('Except for INIT/CLOSE case, only one input argument expected');
  
else
  if ~isstruct(varargin{1}),
    error('First input argument must be ''init'', ''close'', or a struct');
  end
  state= varargin{1};
  %while state.sp.BytesAvailable<state.nBytesPerPoll,
  %  pause(0.01);
  %end
  
  % Receive data packet from COM port and check packet IDs
  chunk= fread(state.sp, state.nBytesPerPoll, 'uint8');
  chunk= cat(1, state.buffer, chunk);
  chunk= bbciutil_cognionicsRemoveIncompletePackets(chunk, state);
  idx= find(chunk==255);
  % IDs at the very end are not considered, because packet # is not available
  if ~isempty(idx) && idx(end)==length(chunk), 
    idx(end)= [];
  end
  
  % if last packet is incomplete, put it to the buffer
  % and exclude that packet from current acquisition
  if length(chunk)-idx(end)+1 < state.nBytesPerPacket,
    state.buffer= chunk(idx(end):end);
    idx(end)= [];
  else
    state.buffer= [];
  end
  if isempty(idx),
    if state.verbose,
      fprintf('[ACQ-COG] Did not receive any complete data block.\n');
    end
    state.buffer= chunk;
    output= {[], [], [], state};
    varargout= output(1:nargout);
    return;
  end
  
  % Extract packet numbers
  if isempty(state.packetNo),   % init case
    state.packetNo= chunk(idx(1)+1)-1;
  end
  packet_counter= [state.packetNo; chunk(idx+1)];
%  fprintf('buffer: #%d, packets: %s\n', state.packetNo, ...
%          str_vec2str(packet_counter(2:end)));
  packet_counter= mod(packet_counter,128);
  unwarp_correction= 128 * (floor(state.packetNo/128) + ...
                            [0; cumsum(diff(packet_counter)<0)]);
  packet_counter= packet_counter + unwarp_correction;
  state.packetNo= packet_counter(end);
%  fprintf('packets unwrapped: %s\n', str_vec2str(packet_counter));
  
  % Obtain signals from data packets
  np= length(idx);
  idxData= repmat(2+[1:3:3*state.nChans]', [1 np]) + ...
           repmat([0:np-1] * state.nBytesPerPacket, [state.nChans 1]);
  idxData= reshape(idxData, [1 np*state.nChans]);
  msb= chunk(idxData);
  x= bitshift(uint32(msb), 16) + ...
     bitshift(uint32(chunk(idxData+1)), 9) + ...
     bitshift(uint32(chunk(idxData+2)), 2);
  x= x + uint32(bitget(msb, 8)) * bitshift(uint32(255), 24);
  cntx= state.scale * double( typecast(x, 'int32') );
  cntx= reshape(cntx, [state.nChans np])';

  % Obtain markers from data packets
  idxTrg= idx(1) + 2 + 3*state.nChans + 1 + state.nBytesPerPacket*[0:np-1];
  mrkDesc= double( bitshift(uint16(chunk(idxTrg)), 8) + ...
                            uint16(chunk(idxTrg+1)) )';
  iNonvoid= find(mrkDesc & diff([state.lastMrkDesc mrkDesc]));
  state.lastMrkDesc= mrkDesc(end);
  mrkTime= 1/state.fs * iNonvoid;
  if state.verbose && ~isempty(iNonvoid),
    fprintf('[ACQ-COG] Markers: %s\n', str_vec2str(mrkDesc(iNonvoid)));
%     for m= 1:length(iNonvoid),
%       fprintf('[ACQ-COG] %6.3f: %s\n', mrkTime(m), mrkDesc(iNonvoid(m)));
%		 end
  end
  
  % Interpolate lost packets
  dpc= diff(packet_counter);
  ilost= find(dpc>1);
  if ~isempty(ilost), 
    if state.verbose,
      fprintf('[ACQ-COG] interpolating %d lost packets after packet #%d\n', ...
              [dpc(ilost)-1, packet_counter(ilost)]');
    end
    [cntx, mapping]= ...
        bbciutil_cognionicsInterpolate(cntx, packet_counter, state);
    mrkTime= 1/state.fs * mapping(iNonvoid)';
  end
  state.lastx= cntx(end,:);
  
  % Apply filter if requested (dfilt.filter automatically saves the state)
  if ~isempty(state.filtHd),
    cntx= filter(state.filtHd, cntx, 1);
  end
  
  output= {cntx, mrkTime, mrkDesc(iNonvoid), state};
end
varargout= output(1:nargout);
