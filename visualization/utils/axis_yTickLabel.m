function ht= axis_yTickLabel(label_list, varargin)
%AXIS_YTICKLABEL - Add y-ticklabels to the current axis
%
%Synopsis:
% H= axis_yTickLabel(LABEL_LIST, <OPT>)
%
%Input:
% LABEL_LIST: string (labels separated by '|') or cell array of strings
% OPT: struct or property/value list of optional properties:
%  .HPos  - horizontal position
%  .YTick - position of yticks. If not provided, get(gca,'YTick') is used.
%  .Color - font color in RGB format. Maybe an [nLabels 3] matrix of color
%           codes
%  .HorizontalAlignment, .VerticalAlignment
%
%Output:
% H: handle to the text object(s)
%
%Note:
% The position of the text object is defined *within* the axis. So you should
% set XLimMode and YLimMode to 'manual' before calling AXIS_TITLE.

% Author(s): Benjamin Blankertz


props= {'YTick'                []       'DOUBLE[-]'
        'HPos'                 -0.03    'DOUBLE[1]'
        'Color'                [0 0 0]  'DOUBLE[- 3]'
        'HorizontalAlignment' 'right'   'CHAR(left center right)'
        'VerticalAlignment'   'middle'  'CHAR(top cap middle baseline bottom)'};

opt= opt_proplistToStruct(varargin{:});
[opt, isdefault]= opt_setDefaults(opt, props);

if ~iscell(label_list),
  if ismember('|',label_list,'legacy'),
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
if isdefault.YTick,
  opt.YTick= get(gca, 'YTick');
end
if length(opt.YTick)~=nLab,
  error('number of labels must match number of xticks');
end
if nLab>1 && size(opt.Color,1)==1,
  opt.Color= repmat(opt.Color, [nLab 1]);
end

opt_fn= fieldnames(opt);
ifp= find(ismember(opt_fn, {'HorizontalAlignment','VerticalAlignment'},'legacy'));
ifp= cat(1, ifp, strmatch('Font', opt_fn));
font_opt= struct_copyFields(opt, opt_fn(ifp));
font_pl= opt_structToProplist(font_opt);

XLim= get(gca, 'XLim');
xx= XLim(1) + opt.HPos*diff(XLim);
yy= opt.YTick;

for tt= 1:nLab,
  ht(tt)= text(xx, yy(tt), label_list{tt});
  set(ht(tt), font_pl{:}, 'Color',opt.Color(tt,:));
end
