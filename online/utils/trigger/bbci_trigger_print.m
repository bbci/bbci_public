function bbci_trigger_print(value)
%BBCI_TRIGGER_PRINT - Proxi for trigger function, just printing

v= clock;
time_str= sprintf('%02d:%02d:%06.3f', v(4), v(5), v(6));
fprintf('[TRIGGER PRINT] trig #%03d at %s\n', value, time_str);
