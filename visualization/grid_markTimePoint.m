function hl = grid_markTimePoint(tp, chans, varargin)
%GRID_MARKTIMEPOINT - Draw a time point inside grid plots as a vertical
%line
%
%grid_markTimePoint(tp, <chans, Linespec>)
%
% IN  tp     - time point [msec]
%     chans  - channels which should be marked, default [] meaning all

if ~exist('chans','var'), chans=[]; end

hsp= gridutil_getSubplots(chans);
for ih= hsp,
  axes(ih);
  yl= get(ih, 'yLim');
  hl= line([tp tp], yl, varargin{:});
  obj_moveBack(hl);
end
