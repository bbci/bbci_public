function marker = stimutil_waitForMarker(varargin)
%STIMUTIL_WAITFORMARKER - Wait until specified marker is received
%
%Synopsis:
% stimutil_waitForMarker(<OPT>)
% or
% stimutil_waitForMarker(STOPMARKERS)
% as shorthand for
% stimutil_waitForMarker('stopmarkers', STOPMARKERS)
% 
%Arguments:
% OPT: struct or property/value list of optional arguments:
% 'stopmarkers', string or cell array of strings which specify those
%     marker types that are awaited, e.g., {'R  1','R128'}. Using 'S' or
%     'R' as stopmarkers matches all Stimulus resp. Response markers.
%     OPT.stopmarker can also be a vector of integers, which are interpreted
%     as stimulus markers. Default: 'R*'.
% 'bv_host': IP or host name of computer on which BrainVision Recorder
%      is running, default 'localhost'.
% 'bv_bbciclose': true or false. If true, perform initially bbciclose.
%
%Example:
% stimutil_waitForMarker('stopmarkers', [254, 255], 'verbose', 1)
%
% 07-2007 Benjamin Blankertz
% 06-2012 Javier Pascual - update, new acquire_fcn used

props = {   'stopmarkers'   [250, 255]          'DOUBLE[2]'
            'bv_host'       'localhost'         'CHAR' 
            'bv_bbciclose'  0                   'BOOL'
            'acquire_fcn'   @bbci_acquire_bv    'FUNC'
            'acquire_param' {}                  'STRUCT'
            'fs'            1000                'DOUBLE'
            'state'         struct              'STRUCT'
            'pause'         0.05                'DOUBLE'
            'verbose'       0                   'BOOL'    
};

if nargin==0,
  marker = props; 
  return
elseif mod(nargin,2)==1 & ~isstruct(varargin{1}),
  stopmarkers= varargin{1};
  opt= opt_proplistToStruct(varargin{2:end});
  opt.stopmarkers= stopmarkers;
else,
  opt= opt_proplistToStruct(varargin{:});
end;

[opt,isdefault] = opt_setDefaults(opt, props);
opt_checkProplist(opt, props);

if isequal(opt.acquire_fcn, @acquire_sigserv),
  [opt,isdefault]= opt_overrideIfDefault(opt, isdefault, 'pause',0);
  if isdefault.fs,
    % get sampling rate from signal server
    [sig_info, dmy, dmy]= mexSSClient('localhost',9000,'tcp');
    opt.fs= sig_info(1);
    acquire_func('close');
  end
end

if isempty(opt.bv_host),
  fprintf('Waiting for marker disabled by OPT. Press any key to continue.\n');
  pause;
  return;
end

if opt.bv_bbciclose,
  bbciclose();
end

if opt.verbose,
  fprintf('connecting to acquisition system\n');
end

if isdefault.state,
  opt.state = opt.acquire_fcn('init');
  opt.state.reconnect= 1;
  [dmy]= opt.acquire_fcn(opt.state);  %% clear the queue
end

if opt.verbose,
  fprintf('waiting for marker %s\n', toString(opt.stopmarkers));
end

stopmarker = 0;
while ~stopmarker,
  if opt.verbose>2,
    fprintf('%s: acquiring data\n', datestr(now,'HH:MM:SS.FFF'));
  end
  [data, markertime, markerdescr, opt.state]= opt.acquire_fcn(opt.state);
  if ~isempty(markerdescr) && opt.verbose>1,
    fprintf('%s: received markers: %s\n', datestr(now,'HH:MM:SS.FFF'), str_vec2str(markerdescr));
  end
  for mm= 1:length(markerdescr),
    for mmm= 1:length(opt.stopmarkers),
      if (markerdescr(mm) == opt.stopmarkers(mmm)),
        stopmarker= 1;
        if opt.verbose,
          fprintf('stop marker received: %d\n', markerdescr(mm));
        end
      end
    end
  end
  pause(opt.pause);  %% this is to allow breaks
end;

opt.acquire_fcn('close');

if nargin>0
  marker = markerdescr(mm);
end;

end
