function H= plot_scalpEvolutionPlusChannel(erp, mnt, clab, ival, varargin)

props= {'LineWidth',       3,                 'DOUBLE[1]';
        'IvalColor',       [.4 1 1; 1 .6 1],  'DOUBLE[- 3]';
        'XUnit',           '[ms]',            'CHAR';
        'YUnit',           '[\muV]',          'CHAR';
        'PrintIval',       0,                 'BOOL';
        'PrintIvalUnits',  1,                 'BOOL';
        'GlobalCLim',      0,                 'BOOL';
        'ScalePos',        'vert',            'CHAR';
        'ShrinkColorbar',  0,                 'DOUBLE';
        'PlotChannel',     1,                 'BOOL';
        'ChannelAtBottom', 0,                 'BOOL';
        'Subplot',         [],                'DOUBLE';
        'SubplotChannel',  [],                'DOUBLE';
        'FigureColor',     [1 1 1],           'DOUBLE[3]';
        'LegendPos',       'Best',            'CHAR'};
props_scalpPattern= plot_scalpPattern;

if nargin==0,
  H= opt_catProps(props, props_scalpPattern);
  return
end

opt= opt_proplistToStruct(varargin{:});
[opt, isdefault]= opt_setDefaults(opt, props);
opt_checkProplist(opt, props, props_scalpPattern);

opt_scalpPattern= opt_substruct(opt, props_scalpPattern(:,1));

H= plot_scalpPattern(mnt, erp, ival, opt_scalpPattern);
