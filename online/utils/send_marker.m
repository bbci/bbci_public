function return_var = send_marker(value,bbci_markers, data_markers)

if nargin == 0,
    return_var = {parallelport, enobio, nouzz, pyffudp};
    return;
end

if isfield(bbci_markers, 'sink'),
    return_var = feval(bbci_markers.sink,value, bbci_markers, data_markers);
else
    return_var = bbci_markers;
end

end


function return_var = parallelport(value, bbci_markers, data_markers),
% not doing too much checking, to increase speed
% force an error when the proper fields are not set. 
% nothing to init or close
switch value,
    case {'init', 'close'};
        return_var = bbci_markers;
        return;
    otherwise,
        ppWrite(bbci_markers.port, value);
end
end

function return_var = nouzz(value, bbci_markers, data_markers),
% using udp, so nothing to init.

switch value,
    case {'init','close'},
        if ~exist('pnet'),
            error(sprintf(['Please make sure that pnet is installed and in path.\nIt can be obtained here:\n' ...
                'http://www.mathworks.de/matlabcentral/fileexchange/345-tcpudpip-toolbox-2-0-6']));
        else
            return_var = bbci_markers;
            return;
        end
    otherwise,
        pnet(bbci_markers.host, 'write', [uint8('M') typecast(uint16(value),'uint8')]);
        pnet(bbci_markers.host, 'writepacket');
end
end

function return_var = enobio(value, bbci_markers, data_markers),
% using tcpip, so now we actually have something to init and close
switch value,
    case 'init',
        if ~exist('pnet'),
            error(sprintf(['Please make sure that pnet is installed and in path.\nIt can be obtained here:\n' ...
                'http://www.mathworks.de/matlabcentral/fileexchange/345-tcpudpip-toolbox-2-0-6']));
        else
            bbci_markers.connection = pnet('tcpconnect', bbci_markers.host, bbci_markers.port);
            if bbci_markers.connection > 0,
                return_val = bbci_markers;
                return;
            else
                error(sprintf('Failed to connect to %s on port %i.', bbci_markers.host, bbci_markers.port));
            end
        end
    case 'close',
        pnet(bbci_markers.connection, 'close');
        return_var = rmfield(bbci_markers, 'connection');
        return;
    otherwise,
        pnet(bbci_markers.connection, 'printf', sprintf('<trigger>%s</trigger>', num2str(value)));
end
end

function RETURN_VAR = FUTURE_IMPLEMENTATIONS(value, bbci_markers, data_markers),
% a marker function must be able to handle 3 situations: 'init', where a
% potential connection is set up, 'close' where the connection is broken
% and the normal case where value contains a(n array of) number(s), or in
% some cases a string, that need to be set as a trigger
switch value,
    case 'init', 
        % init the connection
        return
    case 'close', 
        % close the connection
        return
    otherwise,
        % send the content of value to the connection.
end
end