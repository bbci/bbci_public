function [H, H_cross]= stimutil_cueArrows(dirs, varargin)

props= {'cross'         0       '!DOUBLE[1]'
       };
props_drawArrow= stimutil_drawArrow;

if nargin==0,
  H= opt_catProps(props, props_drawArrow); 
  return
end

opt= opt_proplistToStruct(varargin{:});
opt= set_defaults(opt, props, 1);

for dd= 1:length(dirs),
  if dd<length(dirs),
    h_tmp= stimutil_drawArrow(dirs{dd}, opt, 'cross',0);
  else
    h_tmp= stimutil_drawArrow(dirs{dd}, opt);
  end
  H(dd)= h_tmp.arrow;
end

if opt.cross,
  H_cross= h_tmp.cross;
else
  H_cross= [];
end

set([H H_cross], 'Visible','off');
