function opt= defopt_erps(varargin)
<<<<<<< HEAD
%DEFOPT_ERPS - Properties for plot_channel* functions, optimized for
%plotting ERPs

props= {'LineWidth',0.7 ;
        'AxisType','cross' ;
        'AxisTitleVerticalAlignment', 'top';
        'AxisTitleFontWeight', 'demi';
        'ScaleHPos','left'};

opt= opt_proplistToStruct(varargin{:});
opt= opt_setDefaults(opt, props);
=======

opt= opt_proplistToStruct(varargin{:});
opt= opt_setDefaults(opt, {'LineWidth',0.7 ;
                  'ColorOrder', [1 .59 .12; .3 .3 .3; 0 .59 .8; .9 0 .9];
                  'AxisType','cross' ;
                  'AxisTitleVerticalAlignment', 'top';
                  'AxisTitleFontWeight', 'demi';
                  'ScaleHPos','left'});
>>>>>>> 1e3760d8825e58cbed5ed21822fef45088217528
