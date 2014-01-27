function opt= defopt_scalp_csp(varargin)
%DEFOPT_SCALP_CSP - Properties for plot_scalp* functions, optimized for
%visualizing spatial filters such as CSP

props= {'Shading',              'flat'
        'Extrapolation',        0
        'Resolution',           61
        'Linespec',             {'LineWidth',2, 'Color','k'}
        'CLim',                 'sym'
        'Colormap',             cmap_greenwhitelila(31)
        'Contour',              5
        'ContourPolicy',        'withinrange'
        'ContourLineprop',      {'LineWidth',0.3}};
    
opt= opt_proplistToStruct(varargin{:});
opt= opt_setDefaults(opt, props);