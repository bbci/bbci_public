function opt= defopt_erps(varargin)
%DEFOPT_ERPS - Properties for plot_channel* functions, optimized for
%plotting ERPs

props= {'LineWidth',                    0.7
        'AxisType',                     'cross'
        'AxisTitleVerticalAlignment',   'top'
        'AxisTitleFontWeight',          'demi'
        'ScaleHPos',                    'left'
        'ColorOrder',             [1 .47 .02; .3 .3 .3; 0 .6 .8; .9 0 .9], 
        };

opt= opt_proplistToStruct(varargin{:});
opt= opt_setDefaults(opt, props);
