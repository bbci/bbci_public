function opt= defopt_spec(varargin)
%DEFOPT_SPEC - Properties for plot_channel* functions, optimized for
%plotting spectra

props= {'LineWidth',                    0.7;
        'AxisTitleVerticalAlignment',   'top' ;
        'AxisTitleFontWeight',          'demi'; 
        'ShrinkAxes',                   [0.95 0.9];
        'ScaleHPos',                    'left'; 
        'ScalePolicy',                  'auto'
        };
    
opt= opt_proplistToStruct(varargin{:});
opt= opt_setDefaults(opt, props);