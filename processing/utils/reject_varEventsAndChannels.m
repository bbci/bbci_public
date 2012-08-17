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
% (1) bandpass-filtering (see opt.doBandpass) 
% (2) build epoching for each markers (see also mrk & ival)
% (3) compute variance for each trial
% (4) remove channels with too small variance (see opt.doSilentChans)
% (5) remove extreme outlier trials
% (6) remove trails with a var > threshold, while (for opt.whiskerperc = 10)
%       threshold = percentile(allVar, 90) + opt.whiskerlength * diff(percentile(allVar, 10), percentile(allVar, 90))      
% (7) combined trials/channels rejection, optionally as multi-pass
% 
%

% 08-06 Benjamin Blankertz
% 07-12 Johannes Hoehne - updated documentation and parametarization


props= { 'whiskerperc'     10           'DOUBLE'
         'whiskerlength'   3            'DOUBLE'
         'doMultipass'     0            'BOOL'
         'doRelVar'        0            'BOOL'
         'doUnstabChans'   1            'BOOL'
         'doSilentChans'   1            'BOOL'
         'doBandpass'      1            'BOOL'
         'removeChannelsFirst'     0    'BOOL'
         'band'            [5 40]       'DOUBLE[2]'
         'clab'            {'not','E*'} 'CHAR|CELL{CHAR}'
         'visualize'       0            'BOOL'
         'visu_log'        0            'BOOL'
         'verbose'         0            'BOOL'};

if nargin==0,
  mrk = props; return
end

misc_checkType('cnt', 'STRUCT(x clab)'); 
misc_checkType('mrk', 'STRUCT(time)'); 
misc_checkType('ival', 'DOUBLE[2]'); 

opt= opt_proplistToStruct(varargin{:});

[opt, isdefault]= opt_setDefaults(opt, props);
opt_checkProplist(opt, props);


if opt.doBandpass,
  [b,a]= butter(5, opt.band/cnt.fs*2);
  cnt= proc_channelwise(cnt, opt.clab, 'filt', b, a);
end

fv= proc_segmentation(cnt, mrk, ival, 'Clab',opt.clab);
nEvents= size(fv.x,3);
fv= proc_variance(fv);
V= squeeze(fv.x);

if opt.visualize,
  Vfull= V;
end


nChans= length(fv.clab);
chGood= [1:nChans]';
evGood= 1:nEvents;
if ~isequal(size(V), [nChans nEvents]),
  error('dimension confusion');
end


%% first-pass channels: remove channels with variance droppping to zero
%%  criterium: variance<1 in more than 5% of trials
if opt.doSilentChans,
  rClab= find(mean(V<1,2) > .05);

  V(rClab,:)= [];
  chGood(rClab)= [];
  nfo.chans= {rClab};
else
  rClab= [];
  nfo.chans= {};
end


%% first-pass trials: remove really bad trials
%%  criterium: >= 20% of the channels have excessive variance
perc= percentiles(V(:), [0 100] + [1 -1]*opt.whiskerperc);
thresh= perc(2) + opt.whiskerlength*diff(perc);
EX= ( V > thresh );
rTrials= find( mean(EX,1)>0.2 );

V(:,rTrials)= [];
evGood(rTrials)= [];
nfo.trials= {rTrials};


%% If requested, remove channels first
if opt.removeChannelsFirst,
  goon= 1;
  while goon,
    perc= percentiles(V(:), [0 100] + [1 -1]*opt.whiskerperc);
    thresh= perc(2) + opt.whiskerlength*diff(perc);
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
    goon= goon && opt.doMultipass;
  end
end


%% combined trials/channels rejection, optionally as multi-pass

goon= 1;
while goon,
  perc= percentiles(V(:), [0 100] + [1 -1]*opt.whiskerperc);
  thresh= perc(2) + opt.whiskerlength*diff(perc);
  isout= (V > thresh);
  
  rC= [];
  if sum(isout(:))>0.05*nEvents,
    qu= sum(isout,2)/sum(isout(:));
    rC= find( qu>0.1 & mean(isout,2)>0.05 );
    V(rC,:)= [];
    rClab= [rClab; chGood(rC)];
    nfo.chans= cat(2, nfo.chans, {chGood(rC)});
    chGood(rC)= [];
    %% re-calculate threshold for updated V
    perc= percentiles(V(:), [0 100] + [1 -1]*opt.whiskerperc);
    thresh= perc(2) + opt.whiskerlength*diff(perc);
  else
    nfo.chans= cat(2, nfo.chans, {[]});
  end
  
  rTr= find(any(V > thresh, 1));
  V(:,rTr)= [];
  rTrials= [rTrials evGood(rTr)];
  nfo.trials= cat(2, nfo.trials, {evGood(rTr)});
  evGood(rTr)= [];
  
  goon= opt.doMultipass & ...
        (~isempty(nfo.trials{end}) | ~isempty(nfo.chans{end}));
end


%% if average var is very different from trial-to-trial
%%  the following pass might be useful:
%% calculate relative variance (variance minus average channel var)
%%  and discard trials, whose rel var is about a threshold for
%%  more than 10% of the channels.
if opt.doRelVar,
  Vrel= V - repmat(mean(V,2), [1 size(V,2)]);
  perc= percentiles(Vrel(:), [0 100] + [1 -1]*opt.whiskerperc);
  thresh= perc(2) + opt.whiskerlength*diff(perc);
  rTr= find(mean(Vrel > thresh, 1) > 0.1);
  V(:,rTr)= [];
  rTrials= [rTrials evGood(rTr)];
  nfo.trials= cat(2, nfo.trials, {evGood(rTr)});
  evGood(rTr)= [];
end


%% should we???
%% remove unstable channels
%%  note: this rule is very conservative
if opt.doUnstabChans,
  Vv= var(V')';
  perc= percentiles(Vv, [0 100] + [1 -1]*opt.whiskerperc);
  thresh= perc(2) + opt.whiskerlength*diff(perc);
  rC= find(Vv > thresh);

  V(rC,:)= [];
  rClab= [rClab; chGood(rC)];
  nfo.chans= cat(2, nfo.chans, {chGood(rC)});
  chGood(rC)= [];
end

rClab= fv.clab(rClab);
mrk= mrk_select(mrk, 'not', rTrials);

if opt.verbose && ~isempty(rTrials),
  fprintf('%d artifact trials removed due to variance criterion.\n', ...
          numel(rTrials));
end

if opt.visualize,
  nCols= 51;
  cmap= [0 0 0; jet(nCols); 1 1 1];
  if opt.visu_log,
    Vfull= log(Vfull);
  end
  mi= min(Vfull(:));
  peak= max(Vfull(:));
  perc= percentiles(Vfull(:), [0 100] + [1 -1]*opt.whiskerperc);
  thresh= perc(2) + opt.whiskerlength*diff(perc);
  ma= max(Vfull(find(Vfull < thresh)));
  Vint= 2 + floor(nCols*(Vfull-mi)/(ma+1e-2-mi));
  Vdisp= ones([nChans+4 nEvents+4]);
  Vdisp(3:end-2, 3:end-2)= Vint;
  iClab= sort(chanind(fv, rClab));
  Vdisp(iClab+2, 1)= nCols+2;
  Vdisp(iClab+2, end)= nCols+2;
  Vdisp(1, rTrials+2)= nCols+2;
  Vdisp(end, rTrials+2)= nCols+2;
  clf; set(gcf, 'Color',0.9*[1 1 1]);
  axes('Position',[0.06 0.05 0.93 0.94]);
  image([-1:size(Vfull,2)+2], [1:length(fv.clab)+4], Vdisp);
  colormap(cmap);
  gClab= setdiff(1:length(fv.clab), iClab);
  axis_yticklabel(fv.clab(gClab), 'ytick',2+gClab, ...
                  'hpos', -0.01, 'color',[1 1 1], 'fontsize',7);
  axis_yticklabel(fv.clab(iClab), 'ytick',2+iClab, ...
                  'hpos', -0.01, 'color',[0 0 0], ...
                  'fontsize',10, 'fontweight','bold');
  set(gca, 'TickLength',[0 0]);
  xTick= get(gca, 'XTick');
  xTick= setdiff(xTick, 0);
  set(gca, 'XTick',xTick, 'YTick',[]);
  nfo.V= Vdisp;
  nfo.cmap= cmap;
  nfo.Vrange= [mi ma];
  nfo.Vpeak= peak;
end
