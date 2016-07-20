function dat = proc_ssdbank(dat, freqs)
%PROC_SSDBANK - apply Spatio-Spectral Decomposition (SSD) for a  set of
%frequency bands of interest
%
%Synopsis:
% dat= proc_ssdbank(dat, freqs)
%
%Arguments
%     dat    - data structure of continuous data
%     freqs  - matrix of frequencies bands of interest (nBands x 2)
%                 (See example below)
%             
%Returns:
%     dat    - updated data structure
%
%Description:
% applies SSD (Spatio-Spectral Decomposition) on multiple bands and gives the
% entire bank of decomposed features as output. 
% The flanking frequencies chosen to supress the noise are set default to 
% 1 Hz below and 1 Hz above the band of interest(as described in proc_ssd).
% 
% Example for FREQS:
% Frequency bands of interest: 8-10 Hz and 16-18 Hz, then:
%   freqs = [8 10; 16 18];
%
% SEE also proc_ssd, proc_multiBandSpatialFilter
% 
% 02-2016: irina.e.nicolae@campus.tu-berlin.de

misc_checkType(freqs,'DOUBLE[2 2]');

nBands = length(freqs);
[T, nChans, nEpochs] = size(dat.x);

% check if data is segmented or continous
is_epoched = ndims(dat.x) == 3;
if is_epoched
    % if the data is segmented (i.e. epoched), then concatenate epochs
    dat.x = reshape(permute(dat.x, [1,3,2]), [T*nEpochs, nChans]);
end

% apply SSD on multiple bands
prev_Nc = 0; xo = [];clab={};
for ii= 1:nBands,
    x_ssd = proc_ssd(dat,[freqs(ii,:); freqs(ii,1)-2 freqs(ii,2)+2; freqs(ii,1)-1 freqs(ii,2)+1]); 
    % put all the SSD features together
    xo = [xo x_ssd.x];
    % Update dimensions (needed in case of dimensionality reduction)
    Nc = size(x_ssd.x,2); 
    % Assign channels labels corresponding to nBands 
    clab(prev_Nc+1:prev_Nc+Nc) = cellstr(['_flt' int2str(ii)]);
    prev_Nc = prev_Nc + Nc;
end

% put the data back in the correct format 
if is_epoched
    xo = permute(reshape(xo, [T, nEpochs, size(xo,2)]), [1,3,2]);
end

% save old channel labels after SSD
if isfield(x_ssd,'origClab')
    dat.origClab = x_ssd.origClab;
end
% store the transformed data
dat.x = xo;
dat.clab = clab;