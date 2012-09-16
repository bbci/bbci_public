function ival= select_timeival(erd, mrk, varargin)
%SELECT_TIMEIVAL - For ERD data: select a time interval with good descrimination
%
%Synopsis:
% IVAL= select_timeival(CNT, MRK, <OPT>)
%
%Arguments:
% CNT - Struct of continuous data
% MRK - Struct of markers
% OPT - Struct or property/value list of optinal parameters, see
%    description above
%
%Returns:
% IVAL - Selected time interval

% Author(s): Benjamin Blankertz
%            06-12 Javier Pascual. Modified to allow subsets of electrodes
%
%Description:
%This function is used to select discriminative time intervals for ERD data.
%It is called with band-pass filtered (!!) signals. They are
%Laplace filtered [opt.doLaplace] and then the envelope is calculated
%using the Hilbert transform.
%Then a score is calculated as signed r-square value [opt.scoreProc]
%of the two classes for each channel and time point of the maximal time
%interval [opt.maxIval]. These scores are splitted into positive and
%negative part, rectified (i.e. the negative part is multiplied by -1)
%and then the maximum of positive and -negative part is calculated and
%and smoothed in time by a (centered) moving average of 250ms. The
%average of this score across selected channels is calcuated. Since an
%ERD in one part and an ERS in another part of the time interval within
%one channel is undesirable, but an ERD in one channel and an ERS in
%other channel at the same time is fine, the sign of the score is
%corrected such that it is positive in each channel at the time point
%of dest descrimination.
%Next the two time points having the two highest scores are
%selected. These define the initial interval that is iteratively
%enlarged in the subsequent steps. In each step the interval is
%enlarged either one sample to the lower or to the upper side,
%depending on whether the sum of the score below the lower limit or
%above the upper limit is larger. This process is repeated until the
%score within the selected time interval encompasses 80%
%[opt.threshold] of the total score.
%
%
% See also: select_time_intervals for the use with broadband ERP data

% Author(s): Benjamin Blankertz
%            07-12 Johannes Hoehne, modified documentation and parameter
%            naming


motor_areas= {{'FC5,3','CFC5,3','C5,3','CCP5,3','CP5,3'},
              {'FC1-2','CFC1-2','C1-2','CCP1-2','CP1-2'}, 
              {'FC4,6','CFC4,6','C4,6','CCP4,6','CP4,6'}};

done_laplace = regexpi(erd.clab,'^\w+ lap\w*');
done_laplace = any(cell2mat(done_laplace));

props= { 'filter'         []
         'maxIval'        [250 5000]
         'startIval'      [750 3500]
         'scoreProc'      @proc_rSquareSigned
         'areas'           motor_areas
         'doLaplace'       ~done_laplace
         'laplaceRequireReighborhood'     1
         'threshold'       0.80
         'channelwise'     0 };

if nargin==0,
  ival = props; return
end

misc_checkType(erd, 'STRUCT(x clab)'); 
misc_checkType(mrk, 'STRUCT(time)'); 

opt= opt_proplistToStruct(varargin{:});

[opt, isdefault]= opt_setDefaults(opt, props, 1);
              
if isempty(opt.areas),
  opt.areas= {erd.clab};
end

[score_fcn, score_param]= misc_getFuncParam(opt.scoreProc);

if opt.doLaplace,
  erd= proc_laplacian(erd,'requireCompleteNeighborhood', opt.laplaceRequireReighborhood);
end
if opt.channelwise
  if ~isempty(opt.filter),
    erd= proc_channewise(erd, 'filt', opt.filter.b, opt.filter.a);
  end
  erd= proc_channelwise(erd, 'envelope', 'movAvgMsec', 200);
  erd= proc_channelwise(erd, 'baseline', [], 'trialwise',0);
else
  if ~isempty(opt.filter),
    erd= proc_filt(erd, opt.filter.b, opt.filter.a);
  end
  erd= proc_envelope(erd, 'movAvgMsec', 200);
  erd= proc_baseline(erd, [], 'trialwise',0);
end

erd= proc_segmentation(erd, mrk, opt.maxIval, 'CLab', cat(2, opt.areas{:}));
score= score_fcn(erd, score_param{:});

%% for each channel calc a positive (class 1 > class 2) and a
%% negative score (class 2 > class 1)
[T, nChans]= size(score.x);
scp= max(0, score.x);
scn= max(0, -score.x);
for cc= 1:nChans,
  disc= find(scp(:,cc)<0.1*max(scp(:,cc)));
  scp(disc,cc)= 0;
  disc= find(scn(:,cc)<0.1*max(scn(:,cc)));
  scn(disc,cc)= 0;
end

%% calculate score for each channel and choose good channels
%% (one from each area)
chanscp= sqrt(sum(scp.^2, 1));
chanscn= sqrt(sum(scn.^2, 1));
chanscore= max(chanscp, chanscn);

aaa = 1;
for aa= 1:length(opt.areas),
  ci= util_chanind(score, opt.areas{aa});
  
  if(~isempty(ci)),
    [mm,mi]= max(chanscore(ci));
    chansel(aaa)= ci(mi);
    aaa = aaa + 1;
  end;
 
end

%% determine favorable short time interval
smooth_msec= 250;
smooth_sa= smooth_msec/1000*erd.fs;
timescore= max(scp, scn);
timescore= procutil_movingAverage(timescore, smooth_sa, 'centered');
timescore= mean(timescore(:,chansel),2);
tempscore= zeros(size(timescore));
idx= procutil_getIvalIndices(opt.startIval, erd);
tempscore(idx)= timescore(idx);
[topscore,mm]= max(tempscore);
dt= 100/1000*erd.fs;
bidx= [max(1,mm-dt):min(mm+dt,length(timescore))];

%% determine for each channel the favorable sign of class difference
%% and adjust score accordingly
timescore= score.x(:,chansel);
for aa= 1:length(chansel),
  if mean(scp(bidx,chansel(aa))) < mean(scn(bidx,chansel(aa))),
    timescore(:,aa)= -score.x(:,chansel(aa));
  end
end
timescore= mean(timescore, 2);

%% choose initial ival as limited by the two top score time points
[topscore,mm]= max(timescore);
[ss,si]= sort(timescore);
ivalsel= sort(si(end-1:end));

%% iteratively enlarge ival
absscore= max(timescore, 0);
thresh= opt.threshold*sum(absscore);
while sum(absscore(ivalsel(1):ivalsel(2))) < thresh,
  b= [ivalsel(1)-1 ivalsel(2)+1];
  if ivalsel(1)==1,
    extend_dir= 2;
  elseif ivalsel(2)==T,
    extend_dir= 1;
  else
    d1= timescore(b);
    d2= [max(timescore(1:b(1))); max(timescore(b(2):end))];
    dirscore= d1+d2;
    [mm,extend_dir]= max(dirscore);
  end
  ivalsel(extend_dir)= b(extend_dir);
end

ival= erd.t(ivalsel);
