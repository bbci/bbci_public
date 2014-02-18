function H= grid_markTimeBox(intervals, varargin)
%GRID_MARKTIMEBOX - Draw time intervals inside grid plots with vertical
%lines
%
%H= grid_markTimebox(intervals, <opts>)
%
%Input:
% INTERVALS: vectors, e.g. [min max]
% OPTS:      struct or property/value list with optional fields/properties:
%  .CLab     - channels which should be marked
%  .Color    - Colors of the line
%  .Linespec - linepsec of the box plot (overrides .Color)
%  .Height   - relative Height of the line
%  .VPos     - vertical position of the line
%
%Output:
%   H - handle to graphic opbjects

props = {'Clab',                [],             'CELL{CHAR}|DOUBLE';
         'Color',               0.3*[1 1 1],    'DOUBLE[3]';
         'Linespec',            {},             'CHAR';
         'Height',              0.075,          'DOUBLE';
         'VPos',                0,              'DOUBLE';
         'MoveToBackground',    1,              'BOOL'};

if nargin==0,
  H= props; return
end

opt= opt_proplistToStruct(varargin{:});
opt= opt_setDefaults(opt, props);

opt_checkProplist(opt, props);

if isempty(opt.Linespec),
  opt.Linespec= {'Color',opt.Color};
end

old_ax= gca;
hsp= gridutil_getSubplots(opt.clab);
for ii= 1:length(hsp),
  ih= hsp(ii);
  axes(ih);
  yl= get(ih, 'yLim');
  yh= opt.Height*diff(yl);
  delta= 0.005;
  y_lower= yl(1) + (opt.VPos+delta)*(diff(yl)-yh-delta);
  yy= [y_lower; y_lower+yh];
  for jj = 1:size(intervals, 1),
      H(ii,jj).box= line(intervals(jj,[1 2]), yy([1 1]), opt.Linespec{:});
  end
end
if opt.MoveToBackground,
  obj_moveBack(struct2array(H));
end
Axes(old_ax);
