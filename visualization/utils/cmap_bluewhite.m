function cmap= cmap_bluewhite(m, varargin)
%CMAP_BLUEWHITE - Colormap going from blue to white
%
%Synposis:
%  MAP= cmap_bluewhite(M, <OPT>)
%
%Input:
% M: Size of the colormap (number of entries). Default value: Same size
%     as current colormap
% OPT: Struct or property/value list of optinal properties:
%  .MinSat - minimal saturation (HSV model) from which fading is started
%  .MinVal - minimal value (in HSV model) from which fading is started
%
%Output:
% MAP: A colormap matrix of size [M 3]
%
%Example:
% clf; 
% colormap(cmap_bluewhite(15));
% imagesc(toeplitz(1:15)); colorbar;
%
%See also COLORMAP, HSV2RGB, CMAP_HSVFADE

% 01-2005 Benjamin Blankertz

props= {'MinSat',  0.25,  'DOUBLE[1]'
        'MinVal',  0,     'DOUBLE[1]'};

if nargin<1 | isempty(m),
  m= size(get(gcf,'colormap'),1);
end

opt= opt_proplistToStruct(varargin{:});
[opt, isdefault]= opt_setDefaults(opt, props);
opt_checkProplist(opt, props);

m1= floor(m/2);
m2= m-m1;
map1= cmap_hsvFade(m1+1, 4/6, 1, [opt.MinSat 1]);
map2= cmap_hsvFade(m2+1, 4/6, [1 opt.MinVal], 1);

cmap= [map1; map2(3:end,:)];
