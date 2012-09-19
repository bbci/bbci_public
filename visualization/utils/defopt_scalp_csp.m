function opt= defopt_scalp_csp(varargin)

opt= opt_proplistToStruct(varargin{:});
opt= opt_setDefaults(opt, ...
                  {'Shading','flat'
                  'Extrapolation',0
                  'Resolution', 61
                  'Linespec', {'LineWidth',2, 'Color','k'}
                  'CLim','sym'
                  'Colormap',cmap_greenwhitelila(31)
                  'Contour',5
                  'ContourPolicy','withinrange'
                  'ContourLineprop',{'LineWidth',0.3}});
