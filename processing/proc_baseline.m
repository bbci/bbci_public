function dat= proc_baseline(dat, ival, varargin)
%PROC_BASELINE - substract a baseline from a epoched data structure
%
%Synopsis:
%dat= proc_baseline(dat, <ival>)
%dat= proc_baseline(dat, msec, <pos>)
%dat= proc_baseline(dat, msec, <opts>)
%   
%Arguments:
%      dat  - data structure of epoched data
%      ival - baseline interval [start ms, end ms], default all
%      msec - length of baseline interval in msec
%      pos  - 'beginning' (default), or 'end'
%      classwise - 0 (default)
%      trialwise - 1 (default)
%      channelwise - 0 (default) to save memory
%
%Returns:
%     dat  - updated data structure
%
%Description
% baseline correction for EEG data. For each epoch, the average EEG
% amplitude in the specified interval is substracted for every channel
%
%Examples:
%  [cnt, mrk]= file_readBV(some_file);   %load EEG-data in BV-format
%  mrk= mrk_defineClasses(mrk, {1, 2; 'target','nontarget'}); 
%  epo= proc_segmentation(cnt, mrk, [-200 800], 'CLab', {'Fz','Cz','Pz'});
%  epo = proc_baseline(epo, [-150 0]);
%  epo = proc_baseline(epo, 100, 'beginning'); %results in th same as proc_basline(epo, [-200 -100]), due to the segmentation
%
% SEE proc_medianBaseline

% Benjamin Blankertz


props= {'Pos'      'beginning_exact'  'CHAR(beginning end beginning_exact end_exact)'
        'Classwise'     0       'BOOL'   
        'Trialwise'     1       'BOOL'
        'Channelwise'   0       'BOOL'};

if nargin==0,
  dat = props; return
end

dat = misc_history(dat);
misc_checkType(dat, 'STRUCT(x clab)'); 
misc_checkType(ival,'DOUBLE[1-2]'); 

if length(varargin)==1,
  opt= struct('pos', varargin{1});
else
  opt= opt_proplistToStruct(varargin{:});
end
[opt, isdefault]= opt_setDefaults(opt, props);
opt_checkProplist(opt, props);

dim = ndims(dat.x); % 3D or 4D data


if dim<=3
  [T, nC, nE]= size(dat.x);
elseif dim==4
  [T,freq, nC, nE]= size(dat.x);
else
  error('unexpected number of dimensions in dat.x');
end
nCE= nC*nE;  
  
if ~exist('ival', 'var') || isempty(ival),
  Ti= 1:size(dat.x,1);
  if isfield(dat, 't') && opt.Trialwise,
    dat.refIval= dat.t([1 end]);
  end
else
  if length(ival)==1,
    msec= ival;
    switch(lower(opt.Pos)),
     case 'beginning',
      dat.refIval= dat.t(1) + [0 msec];
      Ti= procutil_getIvalIndices(dat.refIval, dat);
     case 'end',
      dat.refIval= dat.t(end) - [msec 0];
      Ti= procutil_getIvalIndices(dat.refIval, dat);
     case 'beginning_exact', % 150 msec = 15 samples (not 16). 
      Ti= 1:round(msec/1000*dat.fs);
      dat.refIval= [dat.t(Ti(1)) dat.t(Ti(end))];      
     case 'end_exact',
      Ti= T+[-round(msec/1000*dat.fs)+1:0];
      dat.refIval= [dat.t(Ti(1)) dat.t(Ti(end))];
     otherwise
      error('unknown position indicator');
    end
  else
    switch(lower(opt.Pos)),
     case 'beginning_exact', % [-150 0] = 15 samples not 16 (at fs= 100 Hz)
%      len= round(diff(ival)/1000*dat.fs);
%      Ti= procutil_getIvalIndices(ival, dat);
%      Ti= Ti(1:len);
      len= round(diff(ival)/1000*dat.fs);
      Ti= procutil_getIvalIndices(ival, dat);
      Ti= Ti(end-len+1:end);
     otherwise,
      Ti= procutil_getIvalIndices(ival, dat);
    end
    % siamac put this in (gives errors for NIRS data)
    if Ti(1) == -1
        Ti=Ti(2:end);
    end
    dat.refIval= dat.t(Ti([1 end]));
  end
end

%% for dim==5, opt.Channelwise is not yet implemented
if opt.Classwise,
  if opt.Trialwise && ~isdefault.Trialwise,
    error('you cannot use both, classwise and trialwise');
  end
  if dim<=3
    for classIdx= 1:size(dat.y,1),
      idx= find(dat.y(classIdx,:));
      baseline= mean(mean(dat.x(Ti, :, idx), 1), 3);
      if opt.Channelwise,
        for ic= 1:nC,
          dat.x(:,ic,idx)= dat.x(:,ic,idx) - ...
              repmat(baseline(:, ic), [T 1 length(idx)]);
        end
      else
        dat.x(:,:,idx)= dat.x(:,:,idx) - repmat(baseline, [T 1 length(idx)]);
      end
    end
  elseif dim==4
    for classIdx= 1:size(dat.y,1)
      idx= find(dat.y(classIdx,:));
      baseline= mean(mean(dat.x(Ti,:, :, idx), 2), 4);
      dat.x(:,:,:,idx)= dat.x(:,:,:,idx) - repmat(baseline, [T 1 1 length(idx)]);
    end
  end
elseif opt.Trialwise,
  if opt.Channelwise,
    if dim==3
      for ic= 1:nCE,
        dat.x(:,ic)= dat.x(:,ic) - mean(dat.x(Ti,ic));
      end
    elseif dim==4
      for ic= 1:nCE,
        dat.x(:,:,ic)= dat.x(:,:,ic) - repmat(mean(dat.x(Ti,:,ic)),[T 1]);
      end
    end
  else
    baseline= mean(dat.x(Ti,:, :, :), 1);
    dat.x= dat.x - repmat(baseline, [T 1 1 1]);
  end
else
  baseline= mean(mean(dat.x(Ti, :, :), 1), 3);
  if opt.Channelwise,
    for ic= 1:nC,
      dat.x(:,ic,:)= dat.x(:,ic,:) - repmat(baseline(:, ic), [T 1 nE]);
    end
  else
    dat.x= dat.x - repmat(baseline, [T 1 nE]);
  end
end
