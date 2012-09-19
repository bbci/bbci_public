function opt= defopt_spec(varargin)

opt= opt_proplistToStruct(varargin{:});
opt= opt_setDefaults(opt, ...
                  {'LineWidth', 0.7
                   'AxisTitleVerticalAlignment', 'top' 
                   'AxisTitleFontWeight', 'demi' 
                   'ShrinkAxes', [0.95 0.9] 
                   'ScaleHPos','left' 
                   'ScalePolicy','auto'});
