function h_bax= set_backgroundaxis(create)

if nargin<1,
  create= 1;
end

hc= get(gcf, 'children');
ii= 0;
is_bax= 0;
while ~is_bax & ii<length(hc),
  ii= ii+1;
  ud= get(hc(ii), 'UserData');
  is_bax= isequal(ud, 'Backgroundaxis');
end

if is_bax,
  h_bax= hc(ii);
elseif create,
  h_bax= axes('position', [0 0 1 1]);
  set(h_bax, 'Visible','off', 'UserData','Backgroundaxis', ...
             'tickLength',[0 0], 'XLim',[0 1], 'YLim',[0 1]);
%% If you want to have a non transparent background (e.g. for printing)
%% you can do the following
%% >> set(ax, 'Visible','on'); move_objectBack(ax);
%% To this end we set tickLength to 0.
else
  h_bax= [];
end
if ~isempty(h_bax),
  get_backAxes(h_bax);
end
