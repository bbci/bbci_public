function opt= defopt_scalp_power(varargin)
%DEFOPT_SCALP_POWER - Properties for plot_scalp* functions, optimized for
%visualizing spectral power

props= {'Shading'                 'flat'
        'Extrapolation'           1
        'ExtrapolateToMean'       0
        'Resolution'              61
        'CLim'                    'range'
        'IvalColor'               [0.8 0.8 0.8; 0.6 0.6 0.6]
        'LineWidth'               2
        'ChannelLineStyleOrder'   {'thick' 'thin'}
        'Colormap'                cmap_hsvFade(51, [4/6 0], 1, 1)
        'Contour'                 5
        'ContourPolicy'           'strict'
        'ContourLineprop'         {'LineWidth' 0.3}
        'MarkMarkerProperties'    {'MarkerSize' 6, 'LineWidth' 1}
        'GlobalCLim'              1
        'LegendPos'               'NorthEast'};

opt= opt_proplistToStruct(varargin{:});
opt= opt_setDefaults(opt, props);
