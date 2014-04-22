function data_feedback= bbci_apply_sendControl(control_signal, bbci_feedback, data_feedback)
%BBCI_APPLY_SENDCONTROL - Send control signal to application
%
%Synopsis:
%  DATA_FEEDBACK= bbci_apply_sendControl('init', BBCI_FEEDBACK, DATA_FEEDBACK)
%  DATA_FEEDBACK= bbci_apply_sendControl('close', BBCI_FEEDBACK, <DATA_FEEDBACK>)
%  DATA_FEEDBACK= bbci_apply_sendControl(CONTROL_SIGNAL, BBCI_FEEDBACK, DATA_FEEDBACK)
%
%Arguments:
%  CONTROL_SIGNAL - CELL: variable/value list, e.g. {cl_output, 1.253}
%  BBCI_FEEDBACK - Structure defining where and how the control signal is sent,
%      subfield of 'data' structure of bbci_apply, see bbci_apply_structures

% 02-2011 Benjamin Blankertz


%% - INIT
if isequal(control_signal, 'init'),
  switch(bbci_feedback.receiver),
   case '',
    % do nothing
   case 'udp',
    if ~exist('pnet', 'file'),
      global BTB
      addpath(fullfile(BTB.PrivateDir, 'import/tcp_udp_ip'))
    end
    pnet('closeall');
    data_feedback.opt.socke= pnet('udpsocket', 1111); 
    pnet(data_feedback.opt.socke, 'udpconnect', 'localhost', 9100');
   case 'pyff',
%    send_udp_xml('init', bbci_feedback.host, bbci_feedback.port);
	pyff_sendUdp('init',  bbci_feedback.host, bbci_feedback.port);
   case 'tobi_c',
    send_tobi_c_udp('init', bbci_feedback.host, bbci_feedback.port);
    case 'matlab',
    if isfield(bbci_feedback, 'opt'),
      data_feedback.opt= bbci_feedback.opt;
    else
      data_feedback.opt= struct;
    end
   otherwise,
    error('feedback.receiver unknown');
  end
  return;
end

%% - CLOSE
if isequal(control_signal, 'close'),
  switch(bbci_feedback.receiver),
   case 'udp',
		 pnet('closeall');
%    if ~isempty(data_feedback.opt.socke),  
%      pnet(data_feedback.opt.socke, 'close');
%      data_feedback.opt.socke= [];
%    end
   case 'pyff',
%    We do not close this channel, as it is probably still required to
%    send signals to Pyff.
%    send_udp_xml('close');
   case 'tobi_c',
    send_tobi_c_udp('close');
  end
  return;
end

%% - Operation
switch(bbci_feedback.receiver),
 case '',
  % do nothing
 case 'udp',
  if ~isempty(control_signal),
    pnet(data_feedback.opt.socke, 'write', control_signal{:}); 
    pnet(data_feedback.opt.socke, 'writepacket');
	end
 case 'pyff',
   if ~isempty(control_signal),
     pyff_sendUdp(control_signal{:});
   end
 case 'tobi_c',
  if ~isempty(control_signal),
    send_tobi_c_udp('send', control_signal{2}(1));
  end
 case 'matlab',
  idx= find(cellfun(@(x)isequal(x,'cl_output'), control_signal));
  cls_output= control_signal{idx(end)+1};
  data_feedback= bbci_feedback.fcn(cls_output, data_feedback);
end
