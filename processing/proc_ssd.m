function [dat, W, A, lambda]= proc_ssd(dat, freqs, varargin)
% PROC_SSD - Spatio-Spectral Decomposition for a given frequency band of
% interest
%
%Synopsis:
% [DAT, W, A, LAMBDA]= PROC_SSD(DAT, FREQS, <OPT>)
%
% INPUT: 
%     DAT -   data structure of continous data
%     FREQS - 3 x 2 matrix with the cut-off frequencies for the following
%             bands:
%             - first row: pass-band for the signal of interest
%             - second row: pass-band for the noise
%             - third row: stop-band for the noise
%             See the example below. 
% OPT - struct or property/value list of optional properties:
%     .filterOrder  -     filter order used for butterworth bandpass and 
%                         bandstop filtering. Default: 2
%     .epochIndices -     a matrix of size N x 2, where N is the number of 
%                         good (i.e. artifact free) data segments. Each row of 
%                         this matrix contains the first and the last sample index of
%                         a data segment, i.e. epoch_indices(n,:) = [1000, 5000]
%                         means that the n'th segment starts at sample 1000 and
%                         ends at sample 5000. 
%
% OUTPUT:
% DAT       - updated data structure
% W         - SSD projection matrix (filters are in the columns)
% A         - estimated mixing matrix (spatial patterns are in the columns)
% LAMBDA    - generalized eigenvalue score of SSD objective function
%
%              
% 
% Description:
% This is a function for the extraction of neuronal oscillations 
% with optimized signal-to-noise ratio. The algorithm maximizes 
% the power at the center frequency (signal of interest) while simultaneously suppressing it
% at the flanking frequency bins (noise band). 
% 
% Example for FREQS:
% Let us consider that we want to extract oscillations in the 10-12 Hz
% frequency range. Then we define: 
%   freqs = [10 12; 8 14; 9 13]. 
% The first row defines the frequency band of interest, here 10-12 Hz. The 
% second and third row define the pass-pand and stop-band for the noise, respectively.
% Here we have a passband of 8-14 Hz and a stop-band of 9-13 Hz in order 
% to get the noise activity just below and just above the band of interest.
%
%
%
% References:
%
% Nikulin VV, Nolte G, Curio G. A novel method for reliable and fast extraction
% of neuronal EEG/MEG oscillations on the basis of spatio-spectral decomposition.
% NeuroImage, 2011, 55: 1528-1535.
%
% Haufe, S., Dahne, S., & Nikulin, V. V. Dimensionality reduction for the 
% analysis of brain oscillations. NeuroImage, 2014 (accepted for publication)
% DOI: 10.1016/j.neuroimage.2014.06.073

props= {'filterOrder'   3           'INT'
        'epochIndices'  []          'DOUBLE[- -2]'};

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
   
%% compute SSD
[W, A, lambda, ~, X_ssd] = ssd(dat.x, freqs, dat.fs, opt.filterOrder, opt.epochIndices);

%% store the bandpass-filtered data, projected onto the SSD filters

% make sure to put the data in the correct format 
if is_epoched
    X_ssd = permute(reshape(X_ssd, [Te, Ne, size(X_ssd,2)]), [1,3,2]);
end
% store the transformed data
dat.x = X_ssd;


%% rename channel labels and save old channel labels
dat.origClab= dat.clab;
dat.clab=cell(1,size(dat.x,2));
for k=1:size(dat.x,2)
    dat.clab{k} = sprintf('ssd %d',k);
end
