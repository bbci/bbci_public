function mnt= mnt_shrinkNonEegChans(mnt, nonEEGchans)
%mnt= mnt_shrinkNonEegChans(mnt, <nonEEGchans>)

if ~exist('nonEEGchans', 'var'),
  nonEEGchans= util_chanind(mnt, 'E*');
else
  nonEEGchans= util_chanind(mnt, nonEEGchans);
end

mnt.box_sz(:,nonEEGchans)= 0.9*mnt.box_sz(:,nonEEGchans);
mnt.box(:,nonEEGchans)= mnt.box(:,nonEEGchans) + ...
    0.1*((sign(mnt.box(:,nonEEGchans))+1)/2);
