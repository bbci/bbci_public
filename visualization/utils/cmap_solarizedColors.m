function map= cmap_solarizedColors(base)
%CMAP_SOLARIZEDCOLORS - Popular colormap 'solarized' by Ethan Schoonover
%
%Synposis:
% MAP= cmap_solarizedColors(<BASE>)
%
%Input:
% BASE: [BOOL] if true, the base colors BASE03, ... are returned as colormap.
%       Otherwise the colors YELLOW, ORANGE, ..., GREEN are returned.
%Output:
% MAP: A colormap matrix of size [M 3]
%
%Example:
% clf; imagesc(toeplitz(1:8)); colorbar;
% colormap(cmap_solarizedColors);
%
%Reference:
%  http://ethanschoonover.com/solarized
% 
%See also COLORMAP, HSV2RGB, CMAP_RAINBOW

% 06-2015 Benjamin Blankertz


if nargin>0 && base,
  map= [  0  43  54
          7  54  66
         88 110 117
        101 123 131
        131 148 150
        147 161 161
        238 232 213
        253 246 227]/255;
else
  map= [181 137   0; 
        203  75  22;
        220  50  47;
        211  54 130;
        108 113 196;
         38 139 210;
         42 161 152;
        133 153   0]/255;
end

