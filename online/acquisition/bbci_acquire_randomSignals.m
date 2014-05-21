function varargout= bbci_acquire_randomSignals(varargin)
%BBCI_ACQUIRE_RANDOMSIGNALS - Generate random signals
%
%Synopsis:
%  STATE= bbci_acquire_randomSignal('init', <PARAM>)
%  [CNTX, MRKTIME, MRKDESC, STATE]= bbci_acquire_randomSignals(STATE)
%  bbci_acquire_randomSignals('close', STATE)
% 
%Arguments:
%  PARAM - Optional arguments:
%    'marker_mode': [CHAR, default 'global'] specifies how markers should be
%             read:
%                '' means no markers,
%                'global' means checking the global variable ACQ_MARKER, and
%                'pyff_udp' means receiving markers by UDP in the pyff format
%    'fs':    [DOUBLE, default 100] sampling rate
%    'clab':  {CELL of CHAR} channel labels,
%             default {'F3','Fz','F4','C3','Cz','C4','P3','Pz','P4'}.
%    'amp': [DOUBLE, default 30] amplitude of the signals (factor for 'randn')
%    'realtime' - [DOUBLE] For value 1, this function only returns the next
%          block of data, if the time corresponding to OPT.blocksize has
%          elaped since the last delivery of data. Prior to that, empty
%          output is returned (just as the 'true' online acquire function
%          would do while no new data is available).
%          For value 0 (default), this function returns one block of data
%          at each call. Values above 1 result in speeded-up
%          realtime. E.g., for 2 the next block of data is returned, if
%          1/2 of the time corresponding to OPT.blocksize has elapsed since
%          the last delivery of data, which amounts to a speed-up factor of 2.
%    
%Output:
%  STATE - Structure characterizing the incoming signals; fields:
%     'fs', 'clab', and intern stuff
%  CNTX - 'acquired' signals [Time x Channels]
%  The following variables hold the markers that have been 'acquired' within
%  the current block (if any).
%  MRKTIME - DOUBLE: [1 nMarkers] position [msec] within data block.
%  MRKDESC - DOUBLE: [1 nMarkers] corresponding marker values

% 02-2012 Benjamin Blankertz


% This is just for opt.marker_mode='global':
global ACQ_MARKER

if isequal(varargin{1}, 'init'),
  state= opt_proplistToStruct(varargin{2:end});
  default_clab= {'F3','Fz','F4','C3','Cz','C4','P3','Pz','P4'};
  props= {'fs'            100            '!DOUBLE[1]'
          'clab'          default_clab   'CELL{CHAR}'
          'blocksize'     40             '!DOUBLE[1]'
          'amplitude'     30             '!DOUBLE[1]'
          'marker_mode'   'global'       'CHAR(global pyff_udp)'
          'realtime'      0              '!DOUBLE[1]'
         };
  state= opt_setDefaults(state, props, 1);
  state.nChannels= length(state.clab);
  state.blocksize_sa= ceil(state.blocksize*state.fs/1000);
  state.blocksize= state.blocksize_sa*1000/state.fs;
  state.nsamples= 0;
  if state.realtime==0,
    state.realtime= inf;
  end
  state.start_time= tic;
  %  switch(state.marker_mode),
  %   case 'pyff_udp',
  %    state.socket= open_udp_socket();
  %  end
  output= {state};
elseif isequal(varargin{1}, 'close'),
  if length(varargin)>1,
    state= varargin{2};
    switch(state.marker_mode),
     case 'pyff_udp',
      close_udp_socket(state.socket);
    end
  end
  return
elseif length(varargin)~=1,
  error('Except for INIT/CLOSE case, only one input argument expected');
else
  if isstruct(varargin{1}),
    state= varargin{1};
    time_running= toc(state.start_time);
    if time_running < state.nsamples/state.fs/state.realtime,
      output= {[], [], [], state};
      varargout= output(1:nargout);
      return;
    end
    cntx= state.amplitude*randn(state.blocksize_sa, state.nChannels);
    state.nsamples= state.nsamples + state.blocksize_sa;
    switch(state.marker_mode),
     case '',
      mrkTime= [];
      mrkDesc= [];
     case 'pyff_udp',
      packet= receive_udp(sock);
      if ~isempty(packet),
        % we don't know the marker position within the block -> set randomly
        mrkTime= ceil(state.blocksize_sa*rand)*1000/state.fs;
        mrkDesc= str2int(packet);  % -> check format
      else
        mrkTime= [];
        mrkDesc= [];
      end
     case 'global',
      if ~isempty(ACQ_MARKER),
        mrkTime= ceil(state.blocksize_sa*rand)*1000/state.fs;
        mrkDesc= ACQ_MARKER;
        ACQ_MARKER= [];
      else
        mrkTime= [];
        mrkDesc= [];
      end
     otherwise
      error('unknown marker_mode: %s', state.marker_mode);
    end
    output= {cntx, mrkTime, mrkDesc, state};
  else
    error('unrecognized input argument');
  end
end
varargout= output(1:nargout);
