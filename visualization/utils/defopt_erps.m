function opt= defopt_erps(varargin)
% in construction

opt= opt_proplistToStruct(varargin{:});
opt= opt_setDefaults(opt, {'LineWidth',0.7 ;
                  'AxisType','cross' ;
                  'AxisTitleVerticalAlignment', 'top';
                  'AxisTitleFontWeight', 'demi';
                  'ScaleHPos','left'});
