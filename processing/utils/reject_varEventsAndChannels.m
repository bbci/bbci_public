function [mrk, rClab, rTrials, nfo]= ...
    reject_varEventsAndChannels(cnt, mrk, ival, varargin)
%REJECT_VAREVENTSANDCHANNELS - Artifact rejection for events and channels
%
%Synopsis:
% [MRK, RCLAB, RTRIALS]= ...
%    reject_varEventsAndChannels(CNT, MRK, IVAL, ...)
%
%Arguments:
% CNT: data structure of continuous signals
% MRK: event marker structure
% IVAL: time interval (relative to marker events) which is to be checked
% optional properties:
%  .doBandpass:  default 1.
%  .band       :  default [5 40]
%  .clab       :  {'not', 'E*'}
%
%Returns:
% MRK: marker structure in which rejected trials are discarded
% RCLAB: cell array of channel labels of rejected channels
% RTRIALS: indices of rejected trials
%
%Description:
% Method to find artifacts in continuous data with markers. The default
% parameters are optimized to find muscle artifacts in EEG data. The 
% sensitivity of the heuristic can be finetuned with the parameters 
% ''whiskerperc'' and ''whiskerlength''. The procedure of the heuristic can
% be summarized with   :
% 
% (1) bandpass-filtering (see opt.DoBandpass) 
% (2) build epoching for each markers (see also mrk & ival)
% (3) compute variance for each trial
% (4) remove channels with too small variance (see opt.DoSilentChans)
% (5) remove extreme outlier trials, i.e. trials with a var > threshold,
%     while (for opt.Whiskerperc = 10)
%       threshold = percentile(allVar, 90) + opt.Whiskerlength * diff(percentile(allVar, 10), percentile(allVar, 90))      
% (6) combined trials/channels rejection, optionally as multi-pass

% 08-06 Benjamin Blankertz
% 07-12 Johannes Hoehne - updated documentation and parametarization


props= { 'Whiskerperc'     10           'DOUBLE[1]'
         'Whiskerlength'   3            'DOUBLE[1]'
         'TrialThresholdPercChannels'   0.2   'DOUBLE[1]'
         'DoMultipass'     0            'BOOL'
         'DoChannelMultipass'   0       'BOOL'
         'DoRelVar'        0            'BOOL'
         'DoUnstabChans'   1            'BOOL'
         'DoSilentChans'   1            'BOOL'
         'DoBandpass'      1            'BOOL'
         'RemoveChannelsFirst'     0    'BOOL'
         'Band'            [5 40]       'DOUBLE[2]'
         'CLab'            {'not','E*'} 'CHAR|CELL{CHAR}'
         'Visualize'       0            'BOOL'
         'VisuLog'         0            'BOOL'
         'Verbose'         0            'BOOL'};

if nargin==0,
  mrk = props; return
end

misc_checkType(cnt, 'STRUCT(x clab)'); 
misc_checkType(mrk, 'STRUCT(time)'); 
misc_checkType(ival, 'DOUBLE[2]'); 

opt= opt_proplistToStruct(varargin{:});

[opt, isdefault]= opt_setDefaults(opt, props);
opt_checkProplist(opt, props);


if opt.DoBandpass,
  [b,a]= butter(5, opt.Band/cnt.fs*2);
  cnt= proc_channelwise(cnt, opt.CLab, 'filt', b, a);
end

fv= proc_segmentation(cnt, mrk, ival, 'Clab',opt.CLab);
nEvents= size(fv.x,3);
fv= proc_variance(fv);
V= squeeze(fv.x);

if opt.Visualize,
  Vfull= V;
end


nChans= length(fv.clab);
chGood= [1:nChans]';
evGood= 1:nEvents;
if ~isequal(size(V), [nChans nEvents]),
  error('dimension confusion');
end


%% first-pass channels: remove channels with variance droppping to zero
%%  criterium: variance<0.5 in more than 10% of trials
if opt.DoSilentChans,
  rClab= find(mean(V<0.5,2) > .1);

  V(rClab,:)= [];
  chGood(rClab)= [];
  nfo.chans= {rClab};
else
  rClab= [];
  nfo.chans= {};
end


%% first-pass trials: remove really bad trials
%%  criterium: >= opt.TrialThresholdPercChannels (default 20%) of the channels have excessive variance
perc= stat_percentiles(V(:), [0 100] + [1 -1]*opt.Whiskerperc);
thresh= perc(2) + opt.Whiskerlength*diff(perc);
EX= ( V > thresh );
rTrials= find( mean(EX,1)>opt.TrialThresholdPercChannels );

V(:,rTrials)= [];
evGood(rTrials)= [];
nfo.trials= {rTrials};


%% If requested, remove channels first
if opt.RemoveChannelsFirst,
  goon= 1;
  while goon,
    perc= stat_percentiles(V(:), [0 100] + [1 -1]*opt.Whiskerperc);
    thresh= perc(2) + opt.Whiskerlength*diff(perc);
    isout= (V > thresh);
    
    rC= [];
    if sum(isout(:))>0.05*nEvents,
      qu= sum(isout,2)/sum(isout(:));
      rC= find( qu>0.1 & mean(isout,2)>0.05 );
      V(rC,:)= [];
      rClab= [rClab; chGood(rC)];
      nfo.chans= cat(2, nfo.chans, {chGood(rC)});
      chGood(rC)= [];
    end
    if isempty(rC),
      goon= 0;
    end
    goon= goon && opt.DoChannelMultipass;
  end
end


%% combined trials/channels rejection, optionally as multi-pass

goon= 1;
while goon,
  perc= stat_percentiles(V(:), [0 100] + [1 -1]*opt.Whiskerperc);
  thresh= perc(2) + opt.Whiskerlength*diff(perc);
  isout= (V > thresh);
  
  rC= [];
  if sum(isout(:))>0.05*nEvents,  % Should this be nRemainingEvents?
    qu= sum(isout,2)/sum(isout(:));
    rC= find( qu>0.1 & mean(isout,2)>0.05 );
    V(rC,:)= [];
    rClab= [rClab; chGood(rC)];
    nfo.chans= cat(2, nfo.chans, {chGood(rC)});
    chGood(rC)= [];
    %% re-calculate threshold for updated V
    perc= stat_percentiles(V(:), [0 100] + [1 -1]*opt.Whiskerperc);
    thresh= perc(2) + opt.Whiskerlength*diff(perc);
  else
    nfo.chans= cat(2, nfo.chans, {[]});
  end
  
  rTr= find(any(V > thresh, 1));
  V(:,rTr)= [];
  rTrials= [rTrials evGood(rTr)];
  nfo.trials= cat(2, nfo.trials, {evGood(rTr)});
  evGood(rTr)= [];
  
  goon= opt.DoMultipass & ...
        (~isempty(nfo.trials{end}) | ~isempty(nfo.chans{end}));
end


%% if average var is very different from trial-to-trial
%%  the following pass might be useful:
%% calculate relative variance (variance minus average channel var)
%%  and discard trials, whose rel var is about a threshold for
%%  more than 10% of the channels.
if opt.DoRelVar,
  Vrel= V - repmat(mean(V,2), [1 size(V,2)]);
  perc= stat_percentiles(Vrel(:), [0 100] + [1 -1]*opt.Whiskerperc);
  thresh= perc(2) + opt.Whiskerlength*diff(perc);
  rTr= find(mean(Vrel > thresh, 1) > 0.1);
  V(:,rTr)= [];
  rTrials= [rTrials evGood(rTr)];
  nfo.trials= cat(2, nfo.trials, {evGood(rTr)});
  evGood(rTr)= [];
end


%% should we???
%% remove unstable channels
%%  note: this rule is very conservative
if opt.DoUnstabChans,
  Vv= var(V')';
  perc= stat_percentiles(Vv, [0 100] + [1 -1]*opt.Whiskerperc);
  thresh= perc(2) + opt.Whiskerlength*diff(perc);
  rC= find(Vv > thresh);

  V(rC,:)= [];
  rClab= [rClab; chGood(rC)];
  nfo.chans= cat(2, nfo.chans, {chGood(rC)});
  chGood(rC)= [];
end

rClab= fv.clab(rClab);
mrk= mrk_selectEvents(mrk, 'not', rTrials);

if opt.Verbose && ~isempty(rTrials),
  fprintf('%d artifact trials detected due to variance criterion.\n', ...
          numel(rTrials));
end

if opt.Visualize,
  nCols= 51;
  cmap= [0 0 0; jet(nCols); 1 1 1];
  if opt.VisuLog,
    Vfull= log(Vfull);
  end
  mi= min(Vfull(:));
  peak= max(Vfull(:));
  perc= stat_percentiles(Vfull(:), [0 100] + [1 -1]*opt.Whiskerperc);
  thresh= perc(2) + opt.Whiskerlength*diff(perc);
  ma= max(Vfull(find(Vfull < thresh)));
  Vint= 2 + floor(nCols*(Vfull-mi)/(ma+1e-2-mi));
  Vdisp= ones([nChans+4 nEvents+4]);
  Vdisp(3:end-2, 3:end-2)= Vint;
  iClab= sort(util_chanind(fv, rClab));
  Vdisp(iClab+2, 1)= nCols+2;
  Vdisp(iClab+2, end)= nCols+2;
  Vdisp(1, rTrials+2)= nCols+2;
  Vdisp(end, rTrials+2)= nCols+2;
  clf; set(gcf, 'Color',0.9*[1 1 1]);
  axes('Position',[0.06 0.05 0.93 0.94]);
  image([-1:size(Vfull,2)+2], [1:length(fv.clab)+4], Vdisp);
  colormap(cmap);
  gClab= setdiff(1:length(fv.clab), iClab,'legacy');
  axis_yTickLabel(fv.clab(gClab), 'YTick',2+gClab, ...
                  'HPos', -0.01, 'Color',[1 1 1], 'FontSize',7);
  axis_yTickLabel(fv.clab(iClab), 'YTick',2+iClab, ...
                  'HPos', -0.01, 'Color',[0 0 0], ...
                  'FontSize',10, 'FontWeight','bold');
  set(gca, 'TickLength',[0 0]);
  xTick= get(gca, 'XTick');
  xTick= setdiff(xTick, 0,'legacy');
  set(gca, 'XTick',xTick, 'YTick',[]);
  nfo.V= Vdisp;
  nfo.cmap= cmap;
  nfo.Vrange= [mi ma];
  nfo.Vpeak= peak;
end
