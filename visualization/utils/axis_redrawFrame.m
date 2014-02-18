function H= axis_redrawFrame(ax, varargin)
%AXIS_REDRAWFRAME - Redraws the frames of axes. Can be useful when patch
% objects have been drawn, which sometimes overlay the original frame.

props = {'VPos',            0,          '!DOUBLE';
         'LineWidth',       1,          '!DOUBLE'
         };

if nargin==0
  H= props; return
end

opt= opt_proplistToStruct(varargin{:});
[opt, isdefault]= opt_setDefaults(opt, props);
opt_checkProplist(opt, props);

misc_checkTypeIfExists('ax','!GRAPHICS');

old_ax= gca;

for ii= 1:length(ax),
  if isequal(get(ax(ii),'XColor'),[1 1 1]) && ...
        isequal(get(ax(ii),'YColor'),[1 1 1]),
    continue;
  end
  visutil_backaxes(ax(ii));

  xLim= get(ax(ii), 'XLim');
  yLim= get(ax(ii), 'YLim');
  location= {'top','right','bottom','left'};
  XX= [xLim; xLim([2 2]); xLim; xLim([1 1])]';
  YY= [yLim([2 2]); yLim; yLim([1 1]); yLim]';
  if strcmp(get(ax(ii),'box'), 'on'),
    draw_loc= location;
  else
    draw_loc= {get(ax(ii),'XAxisLocation'), get(ax(ii),'YAxisLocation')};
  end
  idx= find(ismember(location, draw_loc,'legacy'));
  hold_state= get(ax(ii), 'NextPlot');
  set(ax(ii), 'NextPlot','add');
  H= plot(XX(:,idx), YY(:,idx), 'LineWidth',opt.LineWidth);
%  set(ax(ii), 'NextPlot','replace');
  set(ax(ii), 'NextPlot',hold_state);
  set(H, 'handleVisibility','off');
  hx= H(find(ismember(location(idx), {'top','bottom'},'legacy')));
  hy= H(find(ismember(location(idx), {'left','right'},'legacy')));
  if ~isempty(hx),
    col= get(ax(ii),'XColor');
    if isequal(col, [1 1 1]),
      delete(hx);
      H= setdiff(H, hx,'legacy');
    else
      set(hx, 'Color',col);
    end
  end
  if ~isempty(hy),
    col= get(ax(ii),'YColor');
    if isequal(col, [1 1 1]),
      delete(hy);
      H= setdiff(H, hy,'legacy');
    else
      set(hy, 'Color',col);
    end
  end
%  legend;  %% restore legend
end

%if old_ax~=ax(end),  %% if this was not checked the legend would disappear
  visutil_backaxes(old_ax);
%end
