function dat= proc_variance(dat, nSections, calcStd)
%PROC_VARIANCE - computes the variance in equally spaced intervals
%
%Synopsis
% dat= proc_variance(dat, <nSections=1, calcStd=0>)
%
% IN   dat       - data structure of continuous or epoched data
%      nSections - number of intervals in which var is to be calculated
%      calcStd   - standard deviation is calculated instead of variance
%
% OUT  dat       - updated data structure
%
%Description
% calculate the variance in 'nSections' equally spaced intervals.
% works for cnt and epo structures.

if nargin==0,
  dat=[];return
end

misc_checkType(dat, 'STRUCT(x)');
misc_checkTypeIfExists('nSections', 'INT');
misc_checkTypeIfExists('calcStd','BOOL');
dat = misc_history(dat);

if ~exist('nSections','var'), nSections=1; end
if ischar(nSections) && strcmpi(nSections,'std'),
  nSections=1;
  calcStd=1;
end
if ~exist('calcStd','var') || (ischar(calcStd) && strcmpi(calcStd,'var')),
  calcStd= 0;
end
if ischar(calcStd) && strcmpi(nSections,'std'),
  calcStd=1;
end


 
[T, nChans, nMotos]= size(dat.x);
inter= round(linspace(1, T+1, nSections+1));
dat.t = [] ; 

xo= zeros(nSections, nChans, nMotos);
for s= 1:nSections,
  Ti= inter(s):inter(s+1)-1;
  if length(Ti)==1,
    warning('calculating variance of scalar');
  end
  if calcStd,
    xo(s,:,:)= reshape(std(dat.x(Ti,:),0,1), [1, nChans, nMotos]);
  else
    if length(Ti)==1,
      xo(s,:,:)= dat.x(Ti,:);
    else
      if nChans*nMotos*length(Ti)<=10^6;
        xo(s,:,:)= reshape(var(dat.x(Ti,:)), [1, nChans, nMotos]);
      else
        for i=1:nMotos
          xo(s,:,i) = var(dat.x(Ti,:,i));
        end
      end
    end
  end
  dat.t(s) = Ti(end);
end

dat.x= xo;
