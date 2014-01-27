function hl= grid_markRange(yRange, chans, varargin)
%GRID_MARKRANGE - Mark range on y axis  inside grid plots as horizontal
%lines
%
%hl= grid_markRange(yRange, <chans, Linespec>)
%
% IN  yRange - range ([lower upper]) on y axis [uV]
%     chans  - channels which should be marked, default [] meaning all

if ~exist('chans','var'), chans=[]; end
if length(yRange)==1, yRange=[-yRange yRange]; end

hsp= gridutil_getSubplots(chans);
for ih= hsp,
  axes(ih);
  xl= get(ih, 'xLim');
  hl= line(xl, yRange([1 1]), varargin{:});
  obj_moveBack(hl);
  hl= line(xl, yRange([2 2]), varargin{:});
  obj_moveBack(hl);
end
