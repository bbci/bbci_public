function [dat,state]= online_movingAverage(dat, state,ms,varargin)
%ONLINE_MOVINGAVERAGE - online computation of moving average
%
%Synopsis:
%[dat,state]= online_movingAverage(dat, state,msec)
%
%Arguments:
%      dat    - data structure of continuous or epoched data
%      state  - to handle online version (some old data)
%      msec   - length of interval in which the moving average is
%               to be calculated in msec
%      varargin
%             - optional parameters will be passed on to ''movingaverage''
%         method - 'centered' or 'causal' (default)
%Returns:
%     dat     - updated data structure
%     state   -  updated state

% bb, ida.first.fhg.de

nSamples= getIvalIndices(ms, dat.fs);
sdat = size(dat.x,1);

if isempty(state)
  state.in = dat.x(max(1,sdat-nSamples+1):end,:);
  dat.x(:,:) = movingAverage(dat.x(:,:), nSamples,varargin{:});
  state.sm = dat.x(max(1,sdat-nSamples+1):end,:);
else
  sst = size(state.sm,1);
  state.in = cat(1,state.in,dat.x(:,:));
  state.sm = cat(1,state.sm,zeros(size(dat.x(:,:))));
  for k = sst+1:sst+sdat
    if k<=nSamples
      state.sm(k,:) = (state.sm(k-1,:)*(k-1)+state.in(k,:))/k;
    else
      state.sm(k,:) = state.sm(k-1,:) + (state.in(k,:)-state.in(k-nSamples,:))/ ...
	  nSamples;
    end
  end
  dat.x = state.sm(sst+1:sst+sdat,:);
  state.sm = state.sm(max(1,sst+sdat-nSamples+1):end,:);
  state.in = state.in(max(1,sst+sdat-nSamples+1):end,:);
end

