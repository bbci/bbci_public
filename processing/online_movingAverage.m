function [dat,state]= online_movingAverage(dat, state, ms)
%ONLINE_MOVINGAVERAGE - online computation of moving average
%
%Synopsis:
%  [DAT, STATE]= online_movingAverage(DAT, STATE, MSEC)
%
%Arguments:
%  DAT	  - data structure of continuous or epoched data
%  STATE  - to handle online version (some old data)
%  MSEC	  - length of interval in which the moving average is
%	    to be calculated in msec
%
%Returns:
%  DAT     - updated data structure
%  STATE   - updated state


nSamples= ms*dat.fs/1000;
sdat = size(dat.x,1);

if isempty(state)
  state.in = dat.x(max(1,sdat-nSamples+1):end,:);
  dat.x(:,:) = procutil_movingAverage(dat.x(:,:), nSamples);
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

