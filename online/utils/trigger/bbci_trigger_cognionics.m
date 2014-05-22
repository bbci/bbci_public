function bbci_trigger_cognionics(value, varargin)

persistent sp

if isnumeric(value),
  if isempty(sp),
    sp= serial('COM16', 'BaudRate',57600);
    fopen(sp);
  end

  fwrite(sp, value, 'uint8');
  return;
end

if ischar(value),
  switch(value),
    case 'init',
      sp= serial('COM16', 'BaudRate',57600);
      fopen(sp);
    case 'close',
      fclose(sp);
      %delete(sp);
  end
end
