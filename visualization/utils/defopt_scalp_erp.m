function opt= defopt_scalp_erp(varargin)
%DEFOPT_SCALP_ERP - Properties for plot_scalp* functions, optimized for
%visualizing interval means of ERPs

props= {'Shading'                 'flat'
        'Extrapolation'           1
        'ExtrapolateToMean'       0
        'Resolution'              71
        'CLim'                    'sym'
        'ShrinkColorbar'          0.2
        'Colormap'                jet(51)
        'Contour'                 5
        'LineWidth'               2
        'ChannelLineStyleOrder'   {'thick' 'thin'}
        'ColorOrder',             [1 .47 .02; .3 .3 .3; 0 .6 .8; .9 0 .9], 
        'IvalColor'               [0.8 0.8 0.8; 0.6 0.6 0.6]
        'ContourPolicy'           'strict'
        'ContourLineprop'         {'LineWidth' 0.3}
        'MarkMarkerProperties'    {'MarkerSize' 6, 'LineWidth' 1}
        'GlobalCLim'              1
        'LegendPos'               'NorthWest'
};

opt= opt_proplistToStruct(varargin{:});
opt= opt_setDefaults(opt, props);
