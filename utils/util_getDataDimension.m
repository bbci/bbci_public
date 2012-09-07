function datadim = util_getDataDimension(dat)
%GETDATADIMENSION - determines whether (disregarding channels) the 
% dataset in DAT is 1D or 2D, using heuristics. 1D data refers to time 
% or frequency data, 2D to time x frequency data.
%
%Usage:
% dim = util_getDataDimension(DAT)
%
%Input:
% DAT  - Struct of data
%
%Output:
% datadim - dimensionality (1 or 2) of the data

ndim = ndims(dat.x);

if ndim==2
  datadim = 1;
  
elseif ndim==3 
  % Could be 1D or 2D (time-frequency) data
  nt = numel(dat.t);
  nc = numel(dat.clab);
  ss = size(dat.x);
  if ss(1)==nt && ss(2)==nc
    datadim = 1;
  elseif ss(2)==nt && ss(3)==nc
    datadim = 2;
  else
    error('Number of elements in t (%d) and clab (%d) does not match with size of x (%s).\n', ...
      nt,nc,num2str(size(dat.x)))
  end
  
elseif ndim==4
  datadim = 2;
  
else
  error('%d data dimensions not supported.\n',ndim)
end

