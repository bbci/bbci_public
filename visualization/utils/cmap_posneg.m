function cmap= cmap_posneg(m)
%CMAP_POSNEG - Colormap going from cyan/blue over white to red/yellow
%
%Synposis:
% MAP= cmap_rainbow(M)
%
%Input:
% M: Size of the colormap (number of entries). Default value: Same size
%    as current colormap
%
%Output:
% MAP: A colormap matrix of size [M 3]
%
%Example:
% clf; 
% colormap(cmap_posneg(65));
% imagesc(toeplitz(1:65)); colorbar;
%
%See also COLORMAP, HSV2RGB, CMAP_HSVFADE

% 01-2005 Benjamin Blankertz


if nargin<1 | isempty(m),
  m= size(get(gcf,'colormap'),1);
end

if mod(m,2)==0,
  warning('m should be odd -> using m+1');
  m= m+1;
end

mb6= floor((m-1)/6);
mq= m-1 - 6*mb6;
m1= mb6;
m2= mb6 + (mq>=2);
m3= mb6 + (mq>=4);
map1= cmap_hsvFade(m1+1, 0, 1, [0.5 1]);
map2= cmap_hsvFade(m2+1, [0 1/6], 1, 1);
map3= cmap_hsvFade(m3+1, 1/6, [1 0], 1);
map4= cmap_hsvFade(m3+1, 3/6, [0 1], 1);
map5= cmap_hsvFade(m2+1, [3/6 4/6], 1, 1);
map6= cmap_hsvFade(m1+1, 4/6, 1, [1 0.5]);
cmap= [map1; map2(2:end,:); map3(2:end,:); ...
       map4(2:end,:); map5(2:end,:); map6(2:end,:)];
cmap= flipud(cmap);
