function ht= axis_title(title_list, varargin)
%AXIS_TITLE - Add a title to the current axis
%
%Synopsis:
% H= axis_title(TITLE, <OPT>)
%
%Input:
% TITLE: string or cell array of strings
% OPT:   struct or property/value list of optional properties:
%  .VPpos - vertical position
%  .Color - font color in RGB format. Maybe an [nTit 3] matrix of color
%           codes
%  .Font* - font properties like fontWeight, fontSize, ...
%  .HorizontalAlignment, .verticalAlignment
%
%Output:
% H: handle to the text object(s)
%
%Note:
% The position of the text object is defined *within* the axis. So you should
% set XLimMode and YLimMode to 'manual' before calling AXIS_TITLE.

props = {   'VPos'                  1.02                   '!DOUBLE';
            'Color'                 [0 0 0]                '!CHAR|!DOUBLE[3]';
            'HorizontalAlignment'   'center'               '!CHAR(left center right)';
            'VerticalAlignment'     'bottom'               '!CHAR(bottom center baseline top)';
            'FontWeight'            get(gca, 'FontWeight') '!CHAR(normal bold light demi)';
            'FontSize'              get(gca, 'FontSize')   '!DOUBLE'
            };

if nargin==0,
  H= props; return
end

opt= opt_proplistToStruct(varargin{:});
[opt, isdefault]= opt_setDefaults(opt, props);
opt_checkProplist(opt, props);
misc_checkType(title_list,'CHAR|CELL{CHAR}');


if opt.VPos<=0 && isdefault.VerticalAlignment,
  opt.VerticalAlignment= 'top';
end

if ~iscell(title_list),
  title_list= {title_list};
end
nTit= length(title_list);
if nTit>1 && size(opt.Color,1)==1,
  opt.Color= repmat(opt.Color, [nTit 1]);
end

opt_fn= fieldnames(opt);
ifp= find(ismember(opt_fn, {'HorizontalAlignment','VerticalAlignment'},'legacy'));
ifp= cat(1, ifp, strmatch('font', opt_fn));
font_opt= struct_copyFields(opt, opt_fn(ifp));
font_pl= opt_structToProplist(font_opt);

gap= 1/nTit;
xx= (gap/2):gap:1;
XLim= get(gca, 'XLim');
xx= XLim(1) + xx*diff(XLim);
YLim= get(gca, 'YLim');
yy= YLim(1) + opt.VPos*diff(YLim);

ht= text(xx, yy*ones(1,nTit), title_list);
set(ht, font_pl{:});
for tt= 1:nTit,
  set(ht(tt), 'color',opt.Color(tt,:));
end
