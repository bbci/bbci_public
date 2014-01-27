function fig_set(varargin)
%FIG_SET

props= {'fn'              1            '!INT'
        'toolsoff'        1            '!BOOL'
        'gridsize'        [2 2]        '!DOUBLE[2]'
        'shrink'          [1 1]        '!DOUBLE[2]'
        'shiftUpwards'    1            '!BOOL'
        'name'            ''           'CHAR'
        'clf'             0            '!BOOL'
        'set'             {}           'PROPLIST'
        'desktopborder'   [0 30 0 0]   '!DOUBLE[4]'
        'windowborder'    [5 20]       '!DOUBLE[2]'
       };

if nargin>0 && isnumeric(varargin{1}),
  opt= opt_proplistToStruct(varargin{2:end});
  opt.fn= varargin{1};
else
  opt= opt_proplistToStruct(varargin{:});
end
[opt, isdefault]= opt_setDefaults(opt, props);

pos_screen= get(0, 'ScreenSize');
actualsize(1)= pos_screen(3) - opt.gridsize(2)*2*opt.windowborder(1);
actualsize(2)= pos_screen(4) - opt.gridsize(1)*sum(opt.windowborder);
actualsize= actualsize - sum(opt.desktopborder([1 2; 3 4]));

fig_size= floor(actualsize./fliplr(opt.gridsize));
iv= mod(opt.gridsize(1) - 1 - floor((opt.fn-1)/opt.gridsize(2)), opt.gridsize(1));
ih= mod(opt.fn-1, opt.gridsize(2));

incr= fig_size + [2*opt.windowborder(1) sum(opt.windowborder)];
fig_pos= opt.desktopborder([1 2]) + opt.windowborder([1 1]) + [ih iv].*incr;
figure(opt.fn);
if opt.toolsoff,
  fig_toolsoff;
end
fig_size_orig= fig_size;
fig_size= round(fig_size .* opt.shrink);
if opt.shiftUpwards && fig_size(2)~=fig_size_orig(2),
  fig_pos(2)= fig_pos(2) + fig_size_orig(2) - fig_size(2);
end
drawnow;
set(opt.fn, 'Position', [fig_pos fig_size]);

if ~isdefault.name,
  set(opt.fn, 'Name',opt.name);
end
if ~isempty(opt.set),
  set(opt.fn, opt.set{:});
end
if opt.clf,
  clf;
end
