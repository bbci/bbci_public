function pos= procutil_lapGetCoordinates(lab, grid)
%PROCUTIL_LABGETCOORDINATES - Internal
%
% Subfuction of proc_laplacian and procutil_getclabForLaplacian


nRows= size(grid,1);
%w_cm= warning('query', 'bci:missing_channels');
%warning('off', 'bci:missing_channels');
ii= util_chanind(grid, lab);
%warning(w_cm);
if isempty(ii),
  pos= [NaN; NaN];
else
  xc= 1+floor((ii-1)/nRows);
  yc= ii-(xc-1)*nRows;
  xc= 2*xc - isequal(grid{yc,1},'<');
  pos= [xc; yc];
end
