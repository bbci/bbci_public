function opt= defopt_scalp_erp(varargin)

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
        'ColorOrder',             [1 .59 .12; .3 .3 .3; 0 .59 .8; .9 0 .9], 
        'IvalColor'               [0.8 0.8 0.8; 0.6 0.6 0.6]
        'ContourPolicy'           'strict'
        'ContourLineprop'         {'LineWidth' 0.3}
        'MarkMarkerProperties'    {'MarkerSize' 6, 'LineWidth' 1}
        'GlobalCLim'              1
        'LegendPos'               'NorthWest'};

opt= opt_proplistToStruct(varargin{:});
opt= opt_setDefaults(opt, props);
