function bbci_trigger_cognionics(value, varargin)

persistent sp port

if isnumeric(value),
  if isempty(sp),
		if isempty(port),
			port= 'COM16';
		end
    sp= serial(port, 'BaudRate',57600);
    fopen(sp);
  end
  
  % hack to circumvent error in the cognionics system
  if value>=255,
    value= 246;
    fprintf('[%s:] replaced trigger with %d.\n', mfilename, value);
  end
  fwrite(sp, value, 'uint8');
  fwrite(sp, 0, 'uint8');
  return;
end

if ischar(value),
  switch(value),
    case 'init',
			if ~isempty(varargin),
				port= varargin{1};
			end
      sp= serial(port, 'BaudRate',57600);
      fopen(sp);
    case 'close',
      fclose(sp);
      %delete(sp);
  end
end
