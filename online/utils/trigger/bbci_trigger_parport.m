function bbci_trigger_parport(value, ioLib, ioAddr)

if isnumeric(value),
  %% --- Hack to make it work with current implementation of ppWrite
  % It should work with 
  % > ppWrite(ioLib, ioAddr, value);
  global IO_LIB
  IO_LIB= ioLib;
  %
  ppWrite(ioAddr, value);
end
