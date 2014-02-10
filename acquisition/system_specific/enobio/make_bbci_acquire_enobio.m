function make_bbci_acquire_bv(debug, nouzz)

clear functions

params = {'enobio_api\Enobio3GAPI.lib'};

params = ['bbci_acquire_enobio.cpp' params];

if nargin>= 1 && 1 == debug
  params = ['-g' '-v' params];
end

if nargin>=2 && 1 == nouzz
    params = ['-g' '-output' 'acquire_nouzz' '-DBV_PORT=32163' params];
end

params = ['-compatibleArrayDims' params];

mex(params{:})

disp('Build completed.')
