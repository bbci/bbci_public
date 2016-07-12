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

% 11-2015 Jan Boelts
% --- --- --- ---

global BTB

% initialization of state structure and LSL streams
if isequal(varargin{1}, 'init'),
    
    % check whether lsl toolbox is on the path
    if ~isdir('liblsl-Matlab')
        error('LSL Toolbox is not on the path. add it via addpath(genpath(''path_to_LSL/liblsl-Matlab''))')
    end
    
    % use default electrode setting
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
    % set default parameters that may adapted from the stream later on
    props= {'fs'            100            '!DOUBLE[1]'
        'clab'          default_clab   'CELL{CHAR}'
        'blocksize'     40             '!DOUBLE[1]'
        'port'          'COM11'        '!CHAR'
        'timeout'       3              '!DOUBLE[1]'
        'filtHd'        []             'STRUCT'
        'verbose'       true           '!BOOL'
        };
    [state, isdefault]= opt_setDefaults(state, props, 1);
    
    % set default filter coeffs
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
    % set number of channels and corresponding values
    state.nChans= length(state.clab);
    state.nBytesPerPacket= 2+3*state.nChans+4;
    nPacketsPerPoll= ceil(state.blocksize/1000*state.fs);
    state.nBytesPerPoll= nPacketsPerPoll*state.nBytesPerPacket;
    
    %%%%%  resolve eeg stream from LSL %%%%%
    eeg = {};
    % load a lsl library
    state.lib = lsl_loadlib();
    % look for the stream several times
    for i=1:3
        % look for stream on the network
        eeg = lsl_resolve_byprop(state.lib,'type','EEG');
        if ~isempty(eeg)
            break
        end
        pause(0.1)
    end
    if isempty(eeg)
        error('No LSL EEG stream on the network')
    else
        % create a new inlet
        % save lsl structures to state structure
        state.inlet.x = lsl_inlet(eeg{1});
        [~, state.starttime] = state.inlet.x.pull_sample();
        state.running = 1;
        % get the stream info object for eeg stream
        eeg_info = state.inlet.x.info();
        
        % set sampling rate of current stream
        if not(state.fs==eeg_info.nominal_srate)
            state.fs = eeg_info.nominal_srate;
            warning('EEG sampling rate is different from default: was adapted from 100 to %i', state.fs)
        end
        % check number of channels
        if not(state.nChans==eeg_info.channel_count())
            state.nChans = eeg_info.channel_count();
            warning('EEG nChans is different from default')
        end
        state.packetNo=[];
        state.buffer= [];
        state.lastx= zeros(1, state.nChans);
        state.scale= 1000000/2^24;
    end
    
    % resolve marker stream, try several times
    mrks = {};
    for i=1:3
        mrks = lsl_resolve_byprop(state.lib, 'name', 'MyMarkerStream', 1, 1);
        if ~isempty(mrks)
            break
        end
        pause(0.1)
    end
    if isempty(mrks)        
        error('No LSL marker stream with name ''MyMarkerStream'' on the network, did set up the marker stream?')
    else
        state.inlet.mrk = lsl_inlet(mrks{1});
        state.lastMrkDesc= 256;
    end
    
    if isempty(state.filtHd),
        reset(state.filtHd);
    end
    output= {state};
% close condition needs the 'state' structure.
elseif isequal(varargin{1}, 'close') && length(varargin)==1
    error('Please use ''close'' option with ''state'' variable as second argument: bbci_lsl_acquire(close, state)');
elseif isequal(varargin{1}, 'close') && isstruct(varargin{2}),
    % close inlets and libraries
    state = varargin{2};
    state.inlet.x.delete(); 
    state.inlet.mrk.delete();
    %state.lib.delete();
    output= {state};
    
elseif length(varargin)~=1,
    error('Except for INIT/CLOSE case, only one input argument expected');
else % this is the running condition that receives and returns the samples
    if ~isstruct(varargin{1}),
        error('First input argument must be ''init'', ''close'', or a struct');
    end
    state= varargin{1};
    
    % get data sample from the inlet
    % set timeout to zero to prevent blocking if there is no marker in the
    % current sample.
    timeout = 0; % in seconds
    [cntx, ~] = state.inlet.x.pull_sample();
    
    % get marker and time
    [mrkDesc, mrkTime] = state.inlet.mrk.pull_sample(timeout);
    % lsl gives mrkTime in relation to the total time of the stream, not
    % the recording. therefore we reset the time to the beginning of the
    % recording. Maybe unneccessary and might be removed? 
    mrkTime = mrkTime-state.starttime;
    
    state.lastMrkDesc= mrkDesc;
    
    % check whether streams are still on
    % if the timeout was exceeded mrkTime will be empty
    state.running = not(isempty(cntx));
    
    % save most recent sample
    state.lastx= cntx;
    
    output = {cntx, mrkTime, mrkDesc, state};
end
varargout= output(1:nargout);
