function bbci_trigger_udpSxxx(value)

persistent udp_socket

if isnumeric(value),
  if isempty(udp_socket),
    fprintf('[%s] Trying to open UDP Socket.\n', mfilename);
    bbci_trigger_udpSxxx('init');
  end
  pnet(udp_socket, 'write', sprintf('S%3d', value));
  %  pnet(udp_socket, 'write', uint8(sprintf('S%3d', value)));
  pnet(udp_socket, 'writepacket');
elseif ischar(value) && strcmp(value, 'init'),
  %pnet('closeall');
  udp_socket= pnet('udpsocket', 1111);
  if udp_socket==-1,
    error('Failed to open UDP socket.');
  end
  pnet(udp_socket, 'udpconnect', 'localhost', 1206);
elseif ischar(value) && strcmp(value, 'close'),
  pnet(udp_socket, 'close');
  udp_socket= [];
end
