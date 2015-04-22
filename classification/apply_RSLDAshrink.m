function out = apply_RSLDAshrink(C, x, sublab)
% APPLY_RSLDA - apply fcn for each subclass
%Synopsis:
%  C   [STRUCT with fields 'subC' and 'sublab_unique'] - RSLDA Classifier
%  X   [DOUBLE [ndim nsamples]] - Data
%
%Returns:
%  OUT  - Classifier output
%
%Description:
%  Apply RSLDA Classifier
%
%See also:
%  APPLY_SEPARATINGHYPERPLANE, TRAIN_RSLDASHRINK

if ~isfield(C, 'subC') || ~isfield(C, 'sublab_unique')
        error('input is not correct! .subC and .sublab_unique is needed')
end    
if nargin==2
    if ~isfield(x, 'x') || ~isfield(x, 'sublab')
        error('input is not correct! in_data.x and in_data.sublab is needed')
    end
    in_data = x;
else
    in_data=[];
    in_data.x = x;
    in_data.sublab = sublab;
end

out = nan(size(C.subC{1}.w,2), length(in_data.sublab));

% subclass-wise processing: apply corresp. subclass cls for each data
% point
kk = 0;
for my_sublab = C.sublab_unique
    kk = kk+1;
	ix_ = in_data.sublab == my_sublab;
    x = in_data.x(:,ix_);
    out(:,ix_) = apply_separatingHyperplane(C.subC{kk}, x);
end

%check if there is a NaN... If so, there had been a data point with a
%subclass label which was not specified in the RSLDA classifier
if any(isnan(out))
    warning('at least one data point has undefined sublab!')
end

end

