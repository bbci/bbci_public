function varargout= bbci_acquire_offline(varargin)
%BBCI_ACQUIRE_OFFLINE - Simulating online acquisition by reading from a file
%
%Synopsis:
%  STATE= bbci_acquire_offline('init', CNT, MRK)
%  STATE= bbci_acquire_offline('init', CNT, MRK, <OPT>)
%  [CNTX, MRKTIME, MRKDESC, STATE]= bbci_acquire_offline(STATE)
%  bbci_acquire_offline('close')
% 
%Arguments:
%  CNT - Structure of continuous data, see file_readBV
%  MRK - Structure of markers, see file_readBVmarkers
%  OPT - Struct or property/value list of optinal properties:
%    .blocksize - [INT] Size of blocks (msec) in which data should be
%          processed, default 40.
%    .realtime - [DOUBLE] For value 1, this function only returns the next
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
%  MRKTIME - DOUBLE: [1 nMarkers] position [msec] within data block
%  MRKDESC - Descriptors of the markers, either in format
%       'numeric': DOUBLE [1 nMarkers] like [52 71], or in format
%       'string':  CELL {1 nMarkers} like {'S 52', 'R  1'}
%
%See also:
%  bbci_apply, bbci_acquire_bv

% 02-2011 Benjamin Blankertz


global BBCI_ACQ_SYNC

if isequal(varargin{1}, 'init'),
  if nargin<3,
    error('CNT and MRK must be provided as input arguments');
  end
  state= opt_proplistToStruct(varargin{4:end});
  props= {'blocksize'   40   '!DOUBLE[1]'
          'realtime'    0    '!DOUBLE[1]'
         };
  state= opt_setDefaults(state, props, 1);
  [cnt, mrk]= varargin{2:3};
  state.lag= 1;
  state.orig_fs= cnt.fs;
  state.fs= cnt.fs;
  state.cnt_step= round(state.blocksize/1000*cnt.fs);
  if state.cnt_step<1,
    warning('increasing blocksize to include one sample');
    state.cnt_step= 1;
  end
  state.cnt_idx= 1:state.cnt_step;
  state.clab= cnt.clab;
  state.cnt= cnt;
  if state.realtime==0,
    state.realtime= inf;
  end
  if isfield(mrk, 'event') && isfield(mrk.event, 'desc'),
    mrk.desc= mrk.event.desc(:)';
  else
    [dmy, mrk.desc]= max(mrk.y);
  end
  state.mrk= mrk;
  state.mrk.time= mrk.time;
  % -- MULTIMODAL
  % Bit of a hack: get source # from bbci_apply_initData
  state.source_no= evalin('caller', 'k');
  BBCI_ACQ_SYNC(state.source_no)= 0;
  % --
  output= {state};
elseif length(varargin)~=1,
  error('Except for INIT case, only one input argument expected');
else
  state= varargin{1};
  if isequal(varargin{1}, 'close'),
    state= struct('cnt_idx', []);      % it is not really to close
    return
  elseif isstruct(varargin{1}),
    if isempty(state.cnt_idx),
      error('file is closed');
    end
    if state.cnt_idx(end) > size(state.cnt.x,1),
      state.running= 0;
      output= {[], [], [], state};
      varargout= output(1:nargout);
      return;
    end
    % -- MULTIMODAL
    BBCI_ACQ_SYNC(state.source_no)= evalin('caller','source.time');
    if state.source_no>1,
      if BBCI_ACQ_SYNC(state.source_no) + state.cnt_step*1000/state.fs ...
              > BBCI_ACQ_SYNC(1),
        output= {[], [], [], state};
        varargout= output(1:nargout);
        return;
      end
    end
    % --
    cntx= state.cnt.x(state.cnt_idx, :);
    si= 1000/state.fs;
    TIMEEPS= si/100;
    mrk_idx= find(state.mrk.time-TIMEEPS > (state.cnt_idx(1)-1)*si & ...
                  state.mrk.time-TIMEEPS <= state.cnt_idx(end)*si);
    mrkTime= state.mrk.time(mrk_idx) - (state.cnt_idx(1)-1)*si;
    mrkDesc= state.mrk.desc(mrk_idx);
    state.cnt_idx= state.cnt_idx + state.cnt_step;
    BBCI_ACQ_SYNC(state.source_no)= BBCI_ACQ_SYNC(state.source_no) + ...
        state.cnt_step*1000/state.fs;
    output= {cntx, mrkTime, mrkDesc, state};
  else
    error('unrecognized input argument');
  end
end
varargout= output(1:nargout);
