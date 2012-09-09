function filt= procutil_lapGetLaplacianFilter(FilterType)
%PROCUTIL_LAPGETLAPLACIANFILTER - Internal
%
% Subfuction of proc_laplacian and procutil_getclabForLaplacian


switch lower(FilterType),
  case 'small',
    filt= [0 -2; 2 0; 0 2; -2 0]';
  case 'large',
   filt= [0 -4; 4 0; 0 4; -4 0]';
  case 'horizontal',
    filt= [-2 0; 2 0]';
  case 'vertical',
    filt= [0 -2; 0 2]';
  case 'bip_to_anterior';
    filt= [0 -2]';
  case 'bip_to_posterior';
    filt= [0 2]';
  case 'bip_to_left';
    filt= [-2 0]';
  case 'bip_to_right';
    filt= [2 0]';
  case 'diagonal',
    filt= [-2 -2; 2 -2; 2 2; -2 2]';
  case 'diagonal_small',
    filt= [-1 -1; 1 -1; 1 1; -1 1]';
  otherwise
    error('unknown filter matrix');
end
