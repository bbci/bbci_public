function [amp, lat, peakChan]= tool_getERPAmplitude(erp, varargin)
%TOOL_GETERPAMPLITUDE - Get amplitude (and latency) of an ERP component
%
%Description: To be applied to ERPs, i.e. after using proc_average. Determines
%  the amplitude (and latency) of a specified ERP component. Works in
%  parallel for different conditions. If option PerChannel is selected,
%  the function returns amplitudes (and latencies) for each channel
%
%Synopsis:
%  [AMP, LAT, PEAKCHAN]= tool_getERPAmplitude(ERP, <OPT>)
%
%Arguments:
%  ERP - Classwise average epochs
%  OPT - struct or property/value list of optional fields/properties:
%    'CLab' - CHAR|CELL{CHAR} Labels of channels that are investigated for
%             peak amplitudes, default '*' (meaning all channels)
%    'Ival' - DOUBLE[1 2] Time interval in which the peak amplitude is to be
%             selected, default [] (meaning the whole epoch is considered)
%    'Polarity' - Polarity of ERP component, i.e. Polarity = +1 searches for
%             positive components, while -1 searches for negative components,
%             default +1
%    'PerChannel' - BOOL - If true, the peak amplitudes are selected in each
%             channel individually, default false.
%    'LatencyPerCondition' - BOOL: If true, the latencies for peak amplitudes
%             are selected individually for each condition. Otherwise, they
%             are selected according to the first condition. Default true
%    'ChannelPerCondition' - BOOL: If true, the channels are selected 
%             individually for their peak amplitudes. Otherwise, they
%             are selected according to the first condition. Default true
%    'Unified'  - [BOOL] Switches off the '*PerCondition' options.
%
%Returns
%  AMP - vector (or matrix) of amplitudes 
%  LAT - vector (or matrix) of latencies
%  PEAKCHAN - labels of channels in which the peak amplitudes are attained.
%        Only available, if 'PerChannel' is selected to be true.
%
%See also
%  proc_average


props= {'CLab'                  '*'      '!CHAR|CELL{CHAR}'
        'Ival'                  []       'DOUBLE[1 2]'
        'Polarity'              1        '!DOUBLE[1]'
        'Unified'               false    '!BOOL'
        'PerChannel'            false    '!BOOL'
        'LatencyPerCondition'   true     '!BOOL'
        'ChannelPerCondition'   true     '!BOOL'
       };

if nargin == 0,
  amp= props;
  return;
end

misc_checkType(erp, 'STRUCT(x)');

opt= opt_proplistToStruct(varargin{:});
[opt, isdefault]= opt_setDefaults(opt, props);
opt_checkProplist(opt, props);

if opt.Unified,
  if ~isdefault.LatencyPerCondition && opt.LatencyPerCondition,
    warning('Option ''Unified'' means ''LatencyPerCondition'' is unselected.');
  end
  if ~isdefault.ChannelPerCondition && opt.ChannelPerCondition,
    warning('Option ''Unified'' means ''ChannelPerCondition'' is unselected.');
  end
  opt.LatencyPerCondition= false;
  opt.ChannelPerCondition= false;
end

if isfield(erp, 'y') && size(erp.x, 3) > size(erp.y,1),
  warning('This function should be applied to AVERAGED epochs.');
end

if ~isempty(opt.Ival),
  erp= proc_selectIval(erp, opt.Ival);
end

if ~isdefault.CLab,
  if ~isfield(erp, 'clab'),
    error('if you specify channels, your data structure needs to have the field ''clab''.');
  end
  erp= proc_selectChannels(erp, opt.CLab);
end

erp.x= erp.x * sign(opt.Polarity);

% get the peak amplitude across time and their time indices (~ latencies)
[amp, tidx]= max(erp.x, [], 1);
% remove leading singleton dimension
amp= shiftdim(amp, 1);
tidx= shiftdim(tidx, 1);

nConditions= size(erp.x, 3);
if ~opt.LatencyPerCondition,
  % choose same time index (~latency) for all conditions according to the 1st
  tidx(:, 2:end)= repmat(tidx(:, 1), [1 size(tidx,2)-1]);
  nChans= size(erp.x, 2);
  for ci= 2:nConditions,
    ind = sub2ind(size(erp.x), tidx(:,ci), (1:nChans)', ci*ones(nChans,1));
    amp(:,ci)= erp.x(ind);
  end
end
lat= erp.t(tidx);

if ~opt.PerChannel,
  % get the peak across channels and their channel indices
  [tmpamp, chidx]= max(amp, [], 1);
  if opt.ChannelPerCondition,
    amp= tmpamp;
    tmplat= lat;
    lat= zeros(1, nConditions);
    for ci= 1:nConditions,
      lat(ci)= tmplat(chidx(ci), ci);
    end
  else
    % choose same channel index for all conditions according to the 1st
    chidx(:)= chidx(1);
    amp= amp(chidx(1),:);
    lat= lat(chidx(1),:);
  end
  peakChan= erp.clab(chidx);
end

% undo polarity switch (in case of opt-Polarity == -1)
amp= amp * sign(opt.Polarity);
