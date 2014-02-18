function cmap= cmap_whitered(m, varargin)
%CMAP_WHITERED - Colormap going from white to red
%
%Synopsis:
% MAP= cmap_whitered(M, <OPT>)
%
%Input:
% M: Size of the colormap (number of entries). Default value: Same size
%    as current colormap
% OPT: Struct or property/value list of optinal properties:
%  .MinSat - minimal saturation (HSV model) from which fading is started
%  .MinVal - minimal value (in HSV model) from which fading is started
%  .MaxVal - maximal value (in HSV model) to which fading is performed
%
%Output:
% MAP: A colormap matrix of size [M 3]
%
%Example:
% clf; 
% colormap(cmap_whitered(15));
% imagesc(toeplitz(1:15)); colorbar;
%
%See also COLORMAP, HSV2RGB, CMAP_HSVFADE


props= {'MinSat',  0.4,  'DOUBLE[1]'
        'MinVal',  0,    'DOUBLE[1]'
        'MaxVal',  0.8,  'DOUBLE[1]'};

if nargin<1 | isempty(m),
  m= size(get(gcf,'colormap'),1);
end

opt= opt_proplistToStruct(varargin{:});
[opt, isdefault]= opt_setDefaults(opt, props);
opt_checkProplist(opt, props);

m1= floor(m/2.5);
m2= m-m1-1;
map1= cmap_hsvFade(m1+1, 0, 1, [opt.MinSat 1]);
map2= cmap_hsvFade(m2+1, 0, [opt.MaxVal opt.MinVal], 1);

cmap= flipud([map1; map2(2:end,:)]);
