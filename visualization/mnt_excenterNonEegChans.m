function mnt= mnt_excenterNonEegChans(mnt, nonEEGchans)
%mnt= mnt_excenterNonEegChans(mnt, <nonEEGchans>)

if ~exist('nonEEGchans', 'var'),
  nonEEGchans= util_chanind(mnt, 'E*');
else
  nonEEGchans= util_chanind(mnt, nonEEGchans);
end

mnt.box(:,nonEEGchans)= mnt.box(:,nonEEGchans) + ...
    0.1*sign(mnt.box(:,nonEEGchans));
