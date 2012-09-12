function dat= proc_filterbank(dat, filt_b, filt_a)
%PROC_FILTEBANK - apply forward filter(s)
%Synopsis:
% dat= proc_filterbank(dat, filt_b, filt_a)
%
%Arguments
%     dat    - data structure of continuous data
%     b, a   - cell array of filter coefficients as obtained by butters
%
%Returns:
%     dat    - updated data structure
%
%Description:
% apply a bank of digital (FIR or IIR) forward filter(s)
%
% SEE online_filterbank, butters

dat = misc_history(dat);

misc_checkType(filt_b,'CELL');
misc_checkType(filt_a,'CELL');

nFilters= length(filt_b);
[T, nChans, nEpochs]= size(dat.x);
nCE= nChans*nEpochs;
xo= zeros([T, nCE*nFilters]);
clab= cell(1, nChans*nFilters);
cc= 1:nCE;
for ii= 1:nFilters,
  clab(cc)= strcat(dat.clab, ['_flt' int2str(ii)]);
  xo(:,cc)= filter(filt_b{ii}, filt_a{ii}, dat.x(:,:));
  cc= cc + nCE;
end
dat.x= xo;
dat.clab= clab;
