function CLim= visutil_unifyCLim(h, CLim)
%VISUTIL_UNIFYCLIM - Unify the CLim in all axes pointed to by handles h or
% in the current figure if no handles are given
%
%Synopsis:
% CLIM= visutil_unifyCLim
% CLIM= visutil_unifyCLim(H)
% CLIM= visutil_unifyCLim(H, CLIM)
%
%Input:
% H: List of axis handles
% CLIM: CLim value to set, otherwise the color limit range among all axes
%       taken

% blanker@cs.tu-berlin.de, 09/2009

if ~exist('h','var') || isempty(h),
  h= get(gcf, 'children');
end
hax= findobj(h, 'Type','axes', 'Tag','');
if ~exist('CLim','var') || isempty(CLim)    
    for hi= 1:length(hax),
        cl(hi,:)= get(hax(hi), 'CLim');
    end
    CLim= [min(cl(:,1)) max(cl(:,2))];
end
set(hax, 'CLim', CLim);
