function opt= defopt_erps(varargin)
%DEFOPT_ERPS - Properties for plot_channel* functions, optimized for
%plotting ERPs

props= {'LineWidth',0.7 ;
        'AxisType','cross' ;
        'AxisTitleVerticalAlignment', 'top';
        'AxisTitleFontWeight', 'demi';
        'ScaleHPos','left'};

opt= opt_proplistToStruct(varargin{:});
opt= opt_setDefaults(opt, props);
