function H= plot_scalp(mnt, w, varargin)

props= {'WClab',                 {},               'CELL{CHAR}';
        'Linespec',              {'k'},            'CELL';
        'Contour',               5,                'DOUBLE';
        'ContourPolicy',         'levels',         'CHAR';
        'ContourLineprop',       {'linewidth',1},  'PROPLIST';
        'ContourLabels',         0,                'BOOL';
        'TicksAtContourLevels',  1,                'BOOL';
        'MarkContour',           [],               'DOUBLE[0-2]';
        'MarkContourLineprop',   {'linewidth',2},  'PROPLIST';
        'Shading',               'flat',           'CHAR';
        'Resolution',            40,               'DOUBLE[1]';
        'Extrapolate',           0,                'BOOL';
        'CLim',                 'sym',             'CHAR|DOUBLE[2]';
        'ShrinkColorbar',        0,                'BOOL';
        'NewColormap',           0,                'BOOL';
        'Interpolation',         'linear',         'CHAR';
        'ScalePos',              'vert',           'CHAR';
        'Extrapolation',         1,                'BOOL';
        'ExtrapolateToMean',     1,                'BOOL';
        'ExtrapolateToZero',     0,                'BOOL';
        'Renderer',              'contourf',       'CHAR';
        'ContourfLevels',        50,               'DOUBLE[1]';
        'ContourMargin',         0,                'DOUBLE[1]';
        'Offset',                [0 0],            'DOUBLE[2]'};

if nargin==0,
  H= props; return
end

opt= opt_proplistToStruct(varargin{:});
opt= opt_setDefaults(opt, props);

opt_checkProplist(opt, props);


% ...
H= [];
