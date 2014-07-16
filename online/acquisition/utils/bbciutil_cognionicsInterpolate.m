function [newx, mapping]= ...
    bbciutil_cognionicsInterpolate(cntx, packet_counter, state)

% Prepend last packet for interpolation
cntx= cat(1, state.lastx, cntx);
% Fill variable for new data with existing values
mapping= packet_counter-packet_counter(1)+1;
np= mapping(end);
newx= zeros(np, state.nChans);
newx(mapping,:)= cntx;

% Interpolate missing packets linearly
dpc= diff(mapping(:))';
for k= find(dpc>1),
  iSupport= mapping([k k+1]);
  iFillin= iSupport(1)+1:iSupport(2)-1;
  newx(iFillin,:)= interp1( iSupport, newx(iSupport,:), iFillin, 'linear' );
end
% delete auxilary entry of last packet
newx(1,:)= [];
