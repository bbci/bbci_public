function h_out= axis_getQuietly(varargin)
%AXIS_GETQUIETLY - Make an axis the current axis without interfering the
% 'Visible' property

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
