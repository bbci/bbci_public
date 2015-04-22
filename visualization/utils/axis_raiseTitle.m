function axis_raiseTitle(ax, rel)
%AXIS_RAISETITLE - Raise the title of a plot
%
%Synposis:
%  axis_raiseTitle(REL_RAISE)
%  axis_raiseTitle(AX, REL_RAISE)
%
%Input:
%  AX:        Handle of the axis. If not specified, the current axis is used.
%  REL_RAISE: Specifies how much the title is to be raise. The measure is
%             relative to the height of the axis.

if nargin==1,
  rel= ax;
  ax= gca;
end

ht= get(ax, 'title');
oldUnits= get(ht, 'units');
set(ht, 'units','normalized');
pos= get(ht, 'position');
set(ht, 'position',pos+[0 rel 0]);
set(ht, 'units',oldUnits);
