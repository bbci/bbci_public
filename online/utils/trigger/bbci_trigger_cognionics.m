function bbci_trigger_cognionics(value, varargin)

persistent sp

if isnumeric(value),
  if isempty(sp),
    sp= serial('COM16', 'BaudRate',57600);
    fopen(sp);
	end

	% hack to circumvent error in the cognionics system
	if value>=255,
		value= 247;
		fprintf('[%s:] replaced trigger with 247.\n', mfilename);
	end
  fwrite(sp, value, 'uint8');
  %fwrite(sp, 0, 'uint8');  % check whether this works. otherwise: timer
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
