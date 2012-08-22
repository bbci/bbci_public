function [out]= online_linearDerivation(dat, A, clab)
%ONLINE_LINEARDERIVATION - computes a linear derivation on continuous or
%epoched data
%
%Synopsis:
%out= online_linearDerivation(dat, A, <clab>)
%
%Arguments:   
%      dat      - data structure of continuous or epoched data
%      A        - spatial filter matrix [nOldChans x nNewChans]
%      clab - cell array of channel labels to be used for new channels,
%
%Returns:  
%      out      - updated data structure
%
% SEE also proc_linearDerivation

%        Benjamin Blankertz
% 07-2012 Johannes Hoehne - Updated documentation and parameter naming
%

out= dat;
out.x= dat.x*A;
if nargin>=3,
  out.clab= clab;
end
