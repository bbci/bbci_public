function map= cmap_rainbow(m, varargin)
%CMAP_RAINBOW - Colormap going from red to violet
%
%Synposis:
% MAP= cmap_rainbow(M, <OPT>)
%
%Input:
% M: Size of the colormap (number of entries). Default value: Same size
%    as current colormap
% OPT: Struct or property/value list of optinal properties:
%  .Sat - Saturation of the colors (in the HSV color model)
%  .Val - Value of the colors (in the HSV color model)
%
%Output:
% MAP: A colormap matrix of size [M 3]
%
%Example:
% clf; imagesc(toeplitz(1:50)); colorbar;
% colormap(cmap_rainbow);
% 
%See also COLORMAP, HSV2RGB, CMAP_HSVFADE

% 01-2005 Benjamin Blankertz


props= {'Sat',  1,  'DOUBLE[1]'
        'Val',  1,  'DOUBLE[1]'};

if nargin==0 || isempty(m),
  m= size(get(gcf,'colormap'),1);
end

opt= opt_proplistToStruct(varargin{:});
[opt, isdefault]= opt_setDefaults(opt, props);
opt_checkProplist(opt, props);

map= cmap_hsvFade(m, [0 21/24], [1 1]*opt.Sat, [1 1]*opt.Val);
