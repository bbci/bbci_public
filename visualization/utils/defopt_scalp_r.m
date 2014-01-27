function opt= defopt_scalp_r(varargin)
%DEFOPT_SCALP_R - Properties for plot_scalp* functions, optimized for
%visualizing (signed, squared) r values

props= {'Extrapolation'          1
        'ExtrapolateToMean'      0
        'Resolution'             71
        'CLim'                   'sym'
        'ShrinkColorbar'         0.2
        'ColorOrder'             [0 0 0]
        'Colormap'               cmap_posneg(51)
        'LineWidth'              2
        'ChannelLineStyleOrder'  {'thick' 'thin'}
        'IvalColor'              [0.8 0.8 0.8; 0.6 0.6 0.6]
        'Contour'                5
        'ContourPolicy'          'withinrange'
        'ContourLineprop'        {'LineWidth' 0.3}
        'MarkMarkerProperties'   {'MarkerSize' 6, 'LineWidth' 1}
        'ChannelAtBottom'        1
        'GlobalCLim'             1
        'LegendPos'              'NorthWest'};

opt= opt_proplistToStruct(varargin{:});
opt= opt_setDefaults(opt, props);
