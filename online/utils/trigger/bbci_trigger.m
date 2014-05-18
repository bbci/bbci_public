function bbci_trigger(value)

global BTB

BTB.Acq.TriggerFcn(value, BTB.Acq.TriggerParam{:});
