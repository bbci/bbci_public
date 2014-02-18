function H= grid_markByBox(fractiles, varargin)
%GRID_MARKBYBOX - Draw error or percentiles box inside grid plots
%
%Synopsis:
% H= grid_markByBox(FRACTILES, <OPT>)
%
%Input:
% FRACTILES: vector, e.g. [min 25%ile median 75%tile max], as obtained
%            by 'stat_percentiles(blah, [])'
% OPTS:      struct or property/value list with optional fields/properties:
%  .CLab     - channels which should be marked
%  .Color    - Color of the box plot
%  .Linespec - linespec of the box plot (overrides .Color)
%  .Height   - relative Height of the box plot, default 0.075
%  .VPos     - vertical position of the box plot (0: bottom, 1: top)
%
%Output:
%   H - handle to graphic objects
%
%Example:
%  grid_plot(erp, mnt, defopt_erps);
%  grid_markBybox(stat_percentiles(mrk.latency, [5 25 50 75 95]);

props = {'Clab',        [],             'CELL{CHAR}|DOUBLE';
         'Color',       0.3*[1 1 1],    'DOUBLE[3]';
         'Linespec',    {},             'CHAR';
         'Height',      0.05,           'DOUBLE';
         'VPos',        0,              'DOUBLE'};

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
  H(ii).median= line(fractiles([3 3]'), [yy], opt.Linespec{:});
  H(ii).whisker_ends= line(fractiles([1 1; 5 5]'), [yy, yy], opt.Linespec{:})';
  H(ii).whisker= line(fractiles([1 2; 4 5]'), [1 1; 1 1]*mean(yy), ...
                      opt.Linespec{:})';
  H(ii).box= line(fractiles([2 4 4 2 2]), yy([1 1 2 2 1]), opt.Linespec{:});
end
obj_moveBack(struct2array(H));
Axes(old_ax);
