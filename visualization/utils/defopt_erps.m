function opt= defopt_erps(varargin)

opt= opt_proplistToStruct(varargin{:});
opt= opt_setDefaults(opt, {'LineWidth',0.7 ;
                  'ColorOrder', [1 .59 .12; .3 .3 .3; 0 .59 .8; .9 0 .9];
                  'AxisType','cross' ;
                  'AxisTitleVerticalAlignment', 'top';
                  'AxisTitleFontWeight', 'demi';
                  'ScaleHPos','left'});
