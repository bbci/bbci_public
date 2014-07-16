function bbci_trigger(varargin)
%BBCI_TRIGGER - Sending triggers to the EEG (or whatever)
%
%Synopsis:
%  bbci_trigger(VALUE)
%  bbci_trigger(BBCI, VALUE)
%
%Arguments:
%  VALUE - Value that is sent as a trigger. Most trigger functions will
%          accept only integers from 1 to 255 as VALUE.
%  BBCI - BBCI variable. This function uses the field BBCI.trigger.
%
%Description:
%  This function calls one of a selection of specific trigger functions.
%  If the BBCI variable is specified, BBCI.trigger.fcn is called with
%    BBCI.trigger.param{:} as additional parameters.
%  Otherwise, the function BTB.Acq.TriggerFcn is called (global variable BTB)
%  with BTB.Acq.TriggerParam{:} as addiotional parameters.


if nargin>1 && isstruct(varargin{1}),
  bbci= varargin{1};
  bbci.trigger.fcn(varargin{2}, bbci.trigger.param{:});
elseif nargin==1,
  global BTB
  BTB.Acq.TriggerFcn(varargin{1}, BTB.Acq.TriggerParam{:});
end
