function props= opt_catProps(props, varargin)
%OPT_CATPROPS - Append property specification lists
%
%Synopsis:
%  PROPSPEC= opt_catProps(PROPSPEC1, <PROPSPEC2, ...>)
%
%Arguments:
%  PROPSPECx: PROPSPECLIST - Property specification list, i.e., CELL of size
%      [N 2] or [N 3], with the first column all being strings.
%
%Returns:
%  PROPSPEC: PROPSPECLIST which is the concatenation of all provided 
%      PROPSPECLISTs.
%
%Description:
%  This function essentially performs 
%    cat(1, PROPSPEC1, PROPSPEC2, ...)
%  but it leaves out rows of PROPSPEC2, ... whose property (i.e., first
%  element) already appeared in an earlier PROPSPECLIST.
%
%Example:
%  props1= {'a', 1; 'b', 2}
%  props2= {'c', 3; 'a', 4}
%  opt_catProps(props1, props2)

% 06-2012 Benjamin Blankertz


props_append= varargin;
for k= 1:length(varargin),
  idx_existing= ismember(props_append{k}(:,1), props(:,1),'legacy');
  props_append{k}(idx_existing,:)= [];
end
props= cat(1, props, props_append{:});
