function mrk= mrk_mergeMarkers(mrk1, mrk2, varargin)
%MRK_MERGEMARKERS - Merge Marker Structs
%
%Description:
% This function merges two or more marker structs into one.
%
%Synopsis:
% MRK= mrk_mergeMarkers(MRK1, MRK2, ...)


misc_checkType(mrk1, 'STRUCT(time)');
misc_checkType(mrk2, 'STRUCT(time)');

if isempty(mrk1),
  mrk= mrk2;
  return;
elseif isempty(mrk2),
  mrk= mrk1;
  return;
end

mrk= mrkutil_appendEventInfo(mrk1, mrk2);
mrk.time= cat(2, mrk1.time(:)', mrk2.time(:)');

%% Labels (mrk.y) and class names (mrk.className)
if xor(isfield(mrk1, 'y'), isfield(mrk2, 'y')),
  error('either none or both marker structres must have field ''y''.');
end 
if isfield(mrk1, 'y'),
  s1= size(mrk1.y);
  s2= size(mrk2.y);
  if isfield(mrk1, 'className') && isfield(mrk2, 'className'),
    mrk.y= [mrk1.y, zeros(s1(1), s2(2))];
    mrk2y= [zeros(s2(1), s1(2)), mrk2.y];
    mrk.className= mrk1.className;
    for ii = 1:length(mrk2.className)
      c = find(strcmp(mrk.className,mrk2.className{ii}));
      if isempty(c)
        mrk.y= cat(1, mrk.y, zeros(1,size(mrk.y,2)));
        mrk.className=  cat(2, mrk.className, {mrk2.className{ii}});
        c= size(mrk.y,1);
      elseif length(c)>1,
        error('multiple classes have the same name');
      end
      mrk.y(c,end-size(mrk2.y,2)+1:end)= mrk2.y(ii,:);
    end
  else
    mrk.y= [[mrk1.y; zeros(s2(1), s1(2))], [zeros(s1(1), s2(2)); mrk2.y]];
  end
end

%% Recursion
if length(varargin)>0,
  mrk= mrk_mergeMarkers(mrk, varargin{1}, varargin{2:end});
end
