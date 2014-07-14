function varargout= procutil_catFilters(varargin)
% PROCUTIL_CATFILTERS - Concatenate several filters into one
%
%Synopsis:
% [B, A]= procutil_catFilters(FILT1, <FILT2>, ...)
% HD= procutil_catFilters(FILT1, <FILT2>, ...)
%
%Arguments:
% FILTx - Filter specified as struct with fields b and a
%
%Output:
% B, A - filter coefficients
% HD   - filter specified as discrete-time filter object


sos= zeros(0, 6);
g= [];

for ii= 1:length(varargin),
  [sos0, g0]= tf2sos(varargin{ii}.b, varargin{ii}.a);
  sos= cat(1, sos, sos0);
  g= cat(1, g, g0);
end

if nargout==2,
  [b, a]= sos2tf(sos, g);
  varargout= {b, a};
elseif nargout==1,
  Hd= dfilt.df2sos(sos, g);
  varargout= {Hd};
end
