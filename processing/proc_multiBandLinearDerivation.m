
function dat_sf = proc_multiBandLinearDerivation(dat,W)
%PROC_MULTIBANDLINEARDERIVATION - Apply linear derivation to multi-band
% data
%
%Synopsis:
% DAT_SF = proc_multiBandLinearDerivation(DAT, W)
%
%Arguments:
% DAT - data structure of epoched and multi-band bandpass filtered data
% W   - cell array with each entry containing the spatial filters (in
%       the columns) of each band
%
%Returns:
% DAT_SF - updated data structure, containing the projected data of all
%          bands, appended as channels
%
%Description:
% The input data structure is assumed to contain pre-filtered channels as
% returned by the function proc_filterbank. proc_multiBandLinearDerivation
% can be used either alone or as a processing step in the crossvalidation
% function.
%
% See also: proc_multiBandSpatialFilter crossvalidation proc_filterbank

% 10-2015: schultze-kraft@tu-berlin.de


misc_checkType(dat,'STRUCT(x clab y)'); 
misc_checkType(W,'CELL');

% get number of frequency bands
band_ix = zeros(1,length(dat.clab));
flt_ix = cellfun(@(x) strfind(x,'flt'),dat.clab);
for ii = 1:length(dat.clab)
    band_ix(ii) = str2double(dat.clab{ii}(flt_ix(ii)+3:end));
end
n_bands = max(band_ix);

% band-wise apply spatial filters to data
dat_sf = [];
for bi = 1:n_bands
    dat2 = proc_selectChannels(dat,sprintf('*flt%d',bi));
    dat2 = proc_linearDerivation(dat2,W{bi});
    dat_sf = proc_appendChannels(dat_sf,dat2);
end