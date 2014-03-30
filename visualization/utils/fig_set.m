function fig_state= fig_set(varargin)
%FIG_SET - Setup a new figure
%
%Synposis:
% FIG_STATE= fig_set(FN)
% FIG_STATE= fig_set(FN, <OPT>)
% FIG_STATE= fig_set(<OPT>)
%
%Input:
% FN:  figure number
% OPT: property/value list or struct of options with fields/properties:
%  .Fn          - figure number, alternative to using the first argument
%  .Name        - name of figure window, default: ''
%  .Silent      - if true, doesn't bring figure to the foreground,
%                 default: false
%  .Hide        - if true, sets the figure 'Visible' property to false,
%                 default: false
%  .Toolsoff    - if true, turns off the toolbar of the figure window,
%                 default: true
%  .Clf         - if true, clears the figure, default: false
%  .Resize      - resize the automatically defined dimensions of the figure
%                 (width, height) by the factors [wf hf], default: [1 1]
%  .GridSize    - figures are successively arranged in a [M x N] grid that
%                 covers the whole screen, according to their figure
%                 number, default: [2 2]
%
%Output:
% FIG_STATE: structure with a 'WasVisible' field, to use with function
%            fig_publish

props= {'Fn'              1            '!INT'
        'Name'            ''           'CHAR'
        'Silent'          0            '!BOOL'
        'Hide'            0            '!BOOL'
        'ToolsOff'        1            '!BOOL'
        'Clf'             0            '!BOOL'
        'Resize'          [1 1]        '!DOUBLE[2]'
        'Square'          0            '!BOOL'
        'GridSize'        [2 2]        '!DOUBLE[2]'
        'Props'           {}           'PROPLIST'
        'ShiftUpwards'    1            '!BOOL'
        'DesktopBorder'   [0 30 0 0]   '!DOUBLE[4]'
        'WindowBorder'    [5 20]       '!DOUBLE[2]'
       };

if nargin>0 && isnumeric(varargin{1}),
  opt= opt_proplistToStruct(varargin{2:end});
  opt.Fn= varargin{1};
else
  opt= opt_proplistToStruct(varargin{:});
end
[opt, isdefault]= opt_setDefaults(opt, props);
opt_checkProplist(opt, props);

pos_screen= get(0, 'ScreenSize');
actualsize(1)= pos_screen(3) - opt.GridSize(2)*2*opt.WindowBorder(1);
actualsize(2)= pos_screen(4) - opt.GridSize(1)*sum(opt.WindowBorder);
actualsize= actualsize - sum(opt.DesktopBorder([1 2; 3 4]));

fig_size= floor(actualsize./fliplr(opt.GridSize));
iv= mod(opt.GridSize(1) - 1 - floor((opt.Fn-1)/opt.GridSize(2)), opt.GridSize(1));
ih= mod(opt.Fn-1, opt.GridSize(2));

incr= fig_size + [2*opt.WindowBorder(1) sum(opt.WindowBorder)];
fig_pos= opt.DesktopBorder([1 2]) + opt.WindowBorder([1 1]) + [ih iv].*incr;

fig_state= struct('WasVisible',[]);
if ishandle(opt.Fn),
  fig_state.WasVisible= get(opt.Fn, 'Visible');
end
if opt.Silent && ishandle(opt.Fn),
  set(0, 'CurrentFigure',opt.Fn);
else
  figure(opt.Fn);
end
if opt.Hide,
  set(opt.Fn, 'Visible','off');
end
if opt.ToolsOff,
  set(gcf, 'ToolBar','none', 'MenuBar','none');
end
fig_size_orig= fig_size;
fig_size= round(fig_size .* opt.Resize);
if opt.ShiftUpwards && fig_size(2)~=fig_size_orig(2),
  fig_pos(2)= fig_pos(2) + fig_size_orig(2) - fig_size(2);
end
drawnow;
set(opt.Fn, 'Position', [fig_pos fig_size]);
if opt.Square,
  oldUnits= get(gcf, 'Units');
  set(gcf, 'Units','Points');
  pos= get(gcf, 'Position');
  pos([3 4])= min(pos([3 4]));
  set(gcf, 'Position',pos);
  set(gcf, 'Units',oldUnits);
end

if ~isdefault.Name,
  set(opt.Fn, 'Name',opt.Name);
end
if ~isempty(opt.Props),
  set(opt.Fn, opt.Props{:});
end
if opt.Clf,
  clf;
end

if nargout==0,
  clear fig_state;
end
