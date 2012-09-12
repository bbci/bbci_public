function fv= proc_selectSamples(fv, idx)
%PROC_SELECTSAMPLES - Select a subset of samples of a data set
% 
%Synopsis:
% FV= xval_selectSamples(FV, IDX)
%
%Arguments:
% FV:  struct of feature vectors
% IDX: indices of the feature to select
%
%Returns:
% FV: reduced set of feature vectors
%
%Description:
% Select a subset of samples (feature vectors) from the feature vector 
% struct fv.
% If your samples are EEG epochs in a struct that has the field
% 'indexedByEpochs' please use the function proc_selectEpochs.
%
%See also xvalidation, proc_selectEpochs

% 07-04 Benjamin Blankertz
if nargin==0,
  fv=[];  return
end

misc_checkType(fv, 'STRUCT(x y)');
fv = misc_history(fv);

%%
nd= ndims(fv.x);
ii= repmat({':'}, [1 nd]);
ii{nd}= idx;

fv.x= fv.x(ii{:});
fv.y= fv.y(:,idx);

if isfield(fv, 'bidx'),
  fv.bidx= fv.bidx(idx);
end
if isfield(fv, 'jit'),
  fv.jit= fv.jit(idx);
end
