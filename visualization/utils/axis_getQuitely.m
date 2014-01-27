function h_out= axis_getQuitely(varargin)
%AXIS_GETQUIETLY - ???
%
%Usage:
%  axis_getQuietly(???
%
%Input:
%  ???:      ????

vis= get(gcf, 'Visible');
if nargin==1,
  axes(varargin{:});
else
  out= axes(varargin{:});
end
set(gcf, 'Visible',vis);

if nargout>0,
  h_out= out;
end
