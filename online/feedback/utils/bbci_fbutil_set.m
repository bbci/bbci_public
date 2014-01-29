function DFE= bbci_fbutil_set(DFE, num, varargin)
%BBCI_FB_UTIL - Utility function for logging trigger and graphical events
%
%Synopsis:
%  DFE= bbci_fbutil_set(DFE, TRIGGER_NO)
%  DFE= bbci_fbutil_set(DFE, HANDLE_IDX, PROPLIST)
%  DFE= bbci_fbutil_set(DATA_FEEDBACK, 'init', HANDLES)
%
%Not implemented yet:
%  DFE= bbci_fbutil_set(DFE, '+')
%  DFE= bbci_fbutil_set(DFE, 'close')
%
%Arguments:
%  DFE - (sub-)STRUCT 'event' of data.feedback variable of bbci_apply.
%             Used internally for storing information.
%  DATA_FEEDBACK - (sub-)STRUCT 'feedback' of data variable of bbci_apply.
%        This function extracts the subfields 'trigger_fcn', 'trigger_param',
%        and 'log' from it.
%  TRIGGER_NO - DOUBLE value of the marker to be set
%  HANDLES - DOUBLE handle of graphical object
%
%Returns:
%  DFE - updated substruct 'state' of DFE

% 08-2012 Benjamin Blankertz


if isnumeric(num) && nargin<3,
% Format:  DF= bbci_fbutil_set(DF, TRIGGER_NO)
  if ~isempty(DFE.trigger_fcn),
    DFE.trigger_fcn(num, DFE.trigger_param{:});
  end
  DFE.log_str= [DFE.log_str, sprintf('# TRIGGER: %d\n', num)];
elseif isnumeric(num),
% Format:  DFE= bbci_fbutil_set(DFE, HANDLE_IDX, PROPLIST)
  set(DFE.handles(num), varargin{:});
  propstr= util_toString(varargin);
  for k= 1:numel(num),
    DFE.log_str= [DFE.log_str sprintf('%d > %s\n', num(k), propstr)];
  end
else
% Format:  DFE= bbci_fbutil_set(DF, 'CMD', ...) with 'CMD'='init', '+', 'close'
  switch(num),
   case 'init',
    DF= DFE;
    DFE= struct_copyFields(DF.opt, {'trigger_fcn', 'trigger_param'});
    DFE= struct_copyFields(DFE, DF, {'log'});
    DFE.handles= varargin{1};
    DFE.log_str= '';
    bbci_log_write(DFE, '# Settings:');
    bbci_prettyPrint(DFE.log.fid, DF.opt, 'prefix','#opt.');
    bbci_log_write(DFE, '# Starting at %s', datestr(now, 'HH:MM:SS.FFF'));
    DFE.start_time= tic;
   case '+',
    time_running= toc(DFE.start_time);
    drawnow;
    bbci_log_write(DFE, [DFE.log_str '# TICK at ' ...
                         sprintf('%08.3fs', time_running)]);
    DFE.log_str= '';
   case 'close',
    bbci_log_write(DFE, '# Ending at %s.', ...
                   datestr(now, 'HH:MM:SS.FFF'));
  end
end
