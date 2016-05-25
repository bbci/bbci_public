
function [dat_sf,W] = proc_multiBandSpatialFilter(dat,method)
%PROC_MULTIBANDSPATIALFILTER - Apply spatial filtering method to multiple
%frequency bands
%
%Synopsis:
% [DAT_SF, W] = proc_multiBandSpatialFilter(DAT, METHOD);
%
%Arguments:
% DAT    - data structure of epoched and pre-filtered data
% METHOD - cell array containing in the first entry a function handle to
%          the spatial filtering method and (optionally) in the following
%          entries parameters for that function
%
%Returns:
% DAT_SF - updated data structure, containing the spatially filtered data
%          of all bands, appended as channels
% W      - cell array with each entry containing the spatial filters (in
%          the columns) of each band
%
%Description:
% The input data structure is assumed to contain pre-filtered channels as
% returned by the function proc_filterbank. proc_multiBandSpatialFilter can
% be used either alone or as a processing step in the crossvalidation
% function.
%
%See also: crossvalidation proc_filterbank proc_multiBandLinearDerivation

% 10-2015: schultze-kraft@tu-berlin.de

misc_checkType(dat,'STRUCT(x clab y)');
misc_checkType(method,'CELL');
procFunc = method{1};
misc_checkType(procFunc,'!FUNC');
if length(method)>1
    procPar = method(2:end);
else
    procPar = {};
end

% get number of frequency bands
band_ix = zeros(1,length(dat.clab));
flt_ix = cellfun(@(x) strfind(x,'flt'),dat.clab);
for ii = 1:length(dat.clab)
    band_ix(ii) = str2double(dat.clab{ii}(flt_ix(ii)+3:end));
end
n_bands = max(band_ix);

% band-wise apply spatial filtering method
W = cell(1,n_bands);
dat_sf = [];
for bi = 1:n_bands
    dat2 = proc_selectChannels(dat,sprintf('*flt%d',bi));
    [dat2,W{bi}] = procFunc(dat2,procPar{:});
    dat_sf = proc_appendChannels(dat_sf,dat2);
end

