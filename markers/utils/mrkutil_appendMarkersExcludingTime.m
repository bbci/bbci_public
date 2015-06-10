function mrk= mrkutil_appendMarkersExcludingTime(mrk1, mrk2)
% MRKUTIL_APPENDMARKERSEXCLUDINGTIME
%
% This functions is used in mrk_mergeMarkers and proc_appendEpochs


misc_checkType(mrk1, 'STRUCT');
misc_checkType(mrk2, 'STRUCT');

if isempty(mrk1),
  mrk= mrk2;
  return;
elseif isempty(mrk2),
  mrk= mrk1;
  return;
end

mrk= mrkutil_appendEventInfo(mrk1, mrk2);

%% Labels (mrk.y) and class names (mrk.className)
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
