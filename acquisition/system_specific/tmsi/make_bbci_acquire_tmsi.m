function make_bbci_acquire_bv(debug, nouzz)

clear functions

params = {'WS2_32.lib'};
params = ['bbci_acquire_tmsi.cpp' params];
params = ['-g' params]
%if nargin>= 1 && 1 == debug
%  params = ['-g' '-v' params];
%end

if nargin>=2 && 1 == nouzz
    params = ['-g' '-output' 'acquire_nouzz' '-DBV_PORT=32163' params];
end

params = ['-compatibleArrayDims' params];

mex(params{:})

disp('Build completed.')
