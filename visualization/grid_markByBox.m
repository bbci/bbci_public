function H= grid_markBybox(fractiles, varargin)
%H= grid_markBybox(fractiles, <opts>)
%
% IN  fractiles - vector, e.g. [min 25%ile median 75%tile max],
%                 as obtained by 'percentiles(blah, [])'.
%     opts - struct or property/value list with optional fields/properties:
%       .clab     - channels which should be marked
%       .Color    - Color of the box plot
%       .Linespec - linepsec of the box plot (overrides .Color)
%       .Height   - relative Height of the box plot, default 0.075
%       .VPos     - vertical position of the box plot (0: bottom, 1: top)
% OUT
%   H - handle to graphic opbjects
%
% EXAMPLE
%  grid_plot(erp, mnt, defopt_erps);
%  grid_markBybox(percentiles(mrk.latency, [5 25 50 75 95]);

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
hsp= grid_getSubplots(opt.clab);
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
move_objectBack(struct2array(H));
Axes(old_ax);
