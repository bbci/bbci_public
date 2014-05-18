%TRIGGER -
%This directory contains the general function bbci_trigger.m
%that allows to send triggers to the acquisition hardware.
%According to BTB.Acq.TriggerFcn it calls one of the specific functions
%(see list below) passing the arguments in BTB.Acq.TriggerParam
%
%  BBCI_TRIGGER - Send trigger to acquistion hardware.
%
%The following function are internal used by BBCI_TRIGGER. They should
%not be called directly.
%
%  BBCI_TRIGGER_PARPORT - Send trigger to the parallel port
%  BBCI_TRIGGER_UDPSXXX - Send trigger via udp in the format 'S%3d'
