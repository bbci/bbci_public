function chunk= bbciutil_cognionicsRemoveIncompletePackets(chunk, state)

idx= find(chunk==255);
dIdx= diff(idx);
invalid= find(dIdx~=state.nBytesPerPacket);

iDel= [];
for k= invalid',
  iDel= cat(2, iDel, idx(k):idx(k+1)-1);
end
chunk(iDel)= [];
