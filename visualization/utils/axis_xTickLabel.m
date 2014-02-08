iunction ht= axis_xTickLabel(label_list, varargin)
%AXIS_XTICKLABEL - Add x-ticklabels to the current axis
%
%Synopsis:
% H= axis_xticklabel(TITLE, <OPT>)
%
%Input:
% LABEL_LIST: string or cell array of strings
% OPT: struct or property/value list of optional properties:
%  .vpos - vertical position
%  .mode - meta setting of other properties. So far besides {1,'normal'}
%     only {2,'vertical'} is implemented.
%  .color - font color in RGB format. Maybe an [nLabels 3] matrix of color
%           codes
%  .font* - font properties like fontWeight, fontSize, ...
%  .horizontalAlignment, .verticalAlignment, .rotation
%
%Output:
% H: handle to the text object(s)
%
%Note:
% The position of the text object is defined *within* the axis. So you should
% set XLimMode and YLimMode to 'manual' before calling AXIS_XTICKLABEL.

props = {'XTick', [], ...
         'Mode', 1, ...
         'HPos', -0.03, ...
         'Color', [0 0 0], ...
         'HorizontalAlignment','center', ...
         'VerticalAlignment','top', ...
         'Rotation',0};

opt= opt_proplistToStruct(varargin{:});
[opt, isdefault]= opt_setDefaults(opt, props);

if ~isequal(opt.Mode, 'normal'),
  switch(opt.Mode),
   case {1, 'normal'},
   case {2, 'vertical'},
    [opt, isdefault]= opt_overrideIfDefault(opt, isdefault, ...
                                            'VPos',-0.015, ...
                                            'HorizontalAlignment','right',...
                                            'VerticalAlignment','middle',...
                                            'Rotation',90);
   otherwise,
    error('mode unknown');
  end
end

if ~iscell(label_list),
  if isnumeric(label_list),
    label_list= str_cprintf('%g', label_list);
  elseif ismember('|',label_list,'legacy'),
    label_str= label_list;
    idx= find(label_str=='|');
    idx= [0, idx, length(label_str)+1];
    nLab= length(idx)-1;
    label_list= cell(1,nLab);
    for ii= 1:nLab,
      label_list{ii}= label_str(idx(ii)+1:idx(ii+1)-1);
    end
  else
    label_list= {label_list};
  end
end
nLab= length(label_list);
if isdefault.xtick,
  opt.xtick= get(gca, 'XTick');
else
  set(gca, 'XTickLabel',[]);
end
if length(opt.xtick)~=nLab,
  error('number of labels must match number of xticks');
end
if nLab>1 & size(opt.color,1)==1,
  opt.color= repmat(opt.color, [nLab 1]);
end

opt_fn= fieldnames(opt);
ifp= find(ismember(lower(opt_fn), ...
                   {'horizontalalignment', ...
                    'verticalalignment', ...
                    'rotation'},'legacy'));
ifp= cat(1, ifp, strmatch('font', opt_fn));
font_opt= copy_struct(opt, opt_fn(ifp));
font_pl= struct2propertylist(font_opt);

xx= opt.xtick;
YLim= get(gca, 'YLim');
yy= YLim(1) + opt.vpos*diff(YLim);

for tt= 1:nLab,
  ht(tt)= text(xx(tt), yy, label_list{tt});
  set(ht(tt), font_pl{:}, 'Color',opt.color(tt,:));
end

if opt.clearoldlabel,
  set(gca, 'XTickLabel','');
end
