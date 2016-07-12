function H= grid_markInterval(ival, chans, markCol)
%GRID_MARKINTERVAL - Draw time interval inside grid plots as colored
%patches
%
%Synopsis:
% grid_markInterval(ival, <chans, markCol>)
% grid_markInterval(ival, <axis_handles, markCol>)
%
%Input:
% IVAL:    interval [msec], may also contain several intervals,
%          each as one row
% CHANS:   channels which should be marked, default [] meaning all
% MARKCOL: Color of the patch, if it is scalar take it as gray value,
%          default 0.8

if ~exist('chans','var'), chans=[]; end
if ~exist('markCol','var'), markCol= 0.85; end
if length(markCol)==1,
  markCol= markCol*[1 1 1];
end

if size(ival,1)>1 && size(ival,2)==2,
  for ib= 1:size(ival,1),
    H(ib)= grid_markInterval(ival(ib,:), chans, markCol);
  end
  return
end


old_ax= gca;
if isnumeric(chans) && ~isempty(chans),
  hsp= chans;
else
  hsp= gridutil_getSubplots(chans);
end
k= 0;
for ih= hsp,
  k= k+1;
  axis_getQuietly(ih);  %% this lets the legend vanish behind the axis
  yPatch= get(ih, 'yLim');
  H.line(:,k)= line(ival([1 2; 1 2]), yPatch([1 1; 2 2]), ...
                  'Color',0.5*markCol, 'LineWidth',0.3);
  
  obj_moveBack(H.line(:,k));
  H.patch(k)= patch(ival([1 2 2 1]), yPatch([1 1 2 2]), markCol);
  obj_moveBack(H.patch(k));
  plotutil_gridOverPatches('Axes', gca, 'XGrid', [], 'YGrid', []);
  %if ~isnan(getfield(get(ih,'UserData'), 'hleg')), %% restore legend
  %  legend;
  %end
end
set(H.line, 'UserData','ival line');
set(H.patch, 'EdgeColor','none', 'UserData','ival patch');
axis_getQuietly(old_ax);
if isfield(get(old_ax,'UserData'),'hleg') && ...
      ~isnan(getfield(get(old_ax,'UserData'), 'hleg')),
  legend;
end
