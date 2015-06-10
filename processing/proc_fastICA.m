function [dat, W, A] = proc_fastICA(dat, varargin)
% PROC_FASTICA - Fast Independent Component Analysis wrapper. 
%
% Fastica estimates the independent components from given multidimensional 
% signals. Each column of matrix dat.x is one observed signal. 
%
% Synopsis:
% [DAT, W, A] = PROC_FASTICA(DAT, <OPT>)
%
%
% INPUT: 
%    DAT       - data structure of continous oor segmented data. For
%                 segmented data, all epochs will be concatenated for the ICA
%                 computation
%                
%
%    <OPT>     - struct or property/value list of optional properties:
%     
%       .fasticaParams      -  Cell containing the parameters for fastica.m
%       in pairs. For more information about the possible optional
%       parameters see FASTICA.m
%
% OUTPUT:
%    DAT       - updated data structure
%    W         - SSD projection matrix (filters are in the columns)
%    A         - estimated mixing matrix (spatial patterns are in the columns)
%
% Description:
% This is wrapper for performing an Independent Component Analysis on the 
% recorded signals using the fastICA algorithm. The algorithm estimates the
% independent components from a given multidimensional signal. It is based 
% on a fixed-point iteration scheme maximizing non-Gaussianity as a measure of 
% statistical independence. See also: FASTICA.m
%
% Examples:
%
%   [outcnt, W, A] = proc_fastICA(incnt);
%   or
%   [outcnt, W, A] = proc_fastICA(incnt, 'fasticaParams', {'approach', 'symm'});
%   or
%   opt.fasticaParams = {'numOfIC', 30, 'maxNumIterations', 500};
%   [outcnt, W, A] = proc_fastICA(incnt, opt);
%
% Pre-processing:
% It is recommended that a high-pass temporal filter be applied to the input 
% vector dat.x before the fastICA. Ex.:
%
% % % High-pass
% % Wps= [0.5 0.01]/dat.fs*2;
% % [n, Wn] = buttord(Wps(1), Wps(2), 3, 40);
% % [b,a] = butter(n, Wn, 'high');
% % dat= proc_filtfilt(dat, b,a);
%
% References:
% Hyvarinen, A. (1999). "Fast and robust fixed-point algorithms for independent 
% component analysis" (PDF). IEEE Transactions on Neural Networks 10 (3): 626?634
%
% See also FASTICA.m


props= { 
        'fasticaParams'  {'verbose','off';}          'CELL'
        };

if nargin==0,
  dat = props; return
end


dat = misc_history(dat);
misc_checkType(dat, 'STRUCT(x clab fs)');
opt = opt_proplistToStruct(varargin{:});
opt = opt_setDefaults(opt, props);
opt_checkProplist(opt, props);


%% check if data is segmented or continous
is_epoched = ndims(dat.x) == 3;
if is_epoched
    % if the data is segmented (i.e. epoched), then concatenate epochs
    [Te, Nc, Ne] = size(dat.x);
    dat.x = reshape(permute(dat.x, [1,3,2]), [Te*Ne, Nc]);
end
   
  
%% Compute ICA    
[icasig, A, W] = fastica(dat.x', opt.fasticaParams{:});
    

%% make sure to put the data in the correct format in case it was epoched
if is_epoched
    X_ica = permute(reshape(icasig', [Te, Ne, Nc]), [1,3,2]);
else
    X_ica = icasig';
end
% store the transformed data
dat.x = X_ica;

% Put W in columns format
 W = W';


end
