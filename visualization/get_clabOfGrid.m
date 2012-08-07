function clab= get_clabOfGrid(mnt)
%GETCLABOFGRID - Channel names of channels Visible in the grid of a montage
%
%Synopsis:
% clab= get_clabOfGrid(mnt)

if isfield(mnt, 'box'),
  idx= find(~isnan(mnt.box(1,:)));
  %% remove index of legend:
  idx(find(idx>length(mnt.clab)))= [];
  clab= mnt.clab(idx);
else
  clab= mnt.clab;
end
