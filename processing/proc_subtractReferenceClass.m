function epo= proc_subtractReferenceClass(epo, epo_ref, varargin)
%PROC_SUBTRACTREFERENCECLASS - subtracts a reference class in epo_ref from the data in epo.
%
%Synopsis:
% EPO= proc_subtractReferenceClass(EPO, EPO_REF, <OPT>)
%
%Arguments:
% EPO -      data structure of epoched data
% EPO_REF -  data structure of epoched data. Must have the same number of
%               epochs and data per epoch as EPO
%
% OPT struct or property/value list of optional arguments:
%  .SubtractFrom - '*' (default), a string matching one of the classes of
%                   EPO_REF.


props= {  'SubtractFrom'   '*' 'CHAR'};

opt = opt_proplistToStruct(varargin{:});
[opt, isdefault] = opt_setDefaults(opt, props);
opt_checkProplist(opt, props);        

misc_checkType(epo, 'STRUCT(x className y)'); 
misc_checkType(epo_ref, 'STRUCT(x className y)'); 

clInd= procutil_getClassIndices(epo, opt.SubtractFrom);
nClasses= length(clInd);
global_ref= 1;
if size(epo_ref.x, 3)>1,
  epo_ref= proc_average(epo_ref);
  if size(epo_ref.x, 3)>1,
    if size(epo_ref.x, 3) ~= nClasses,
      error('#epochs in epo_ref must be 1 or equal to #classes in epo.');
    end
    global_ref= 0;
  end
end

ref_class= 1;
idx= find(any(epo.y(clInd,:),1));
nEpochs= length(idx);
for ee= 1:nEpochs,
  ii= idx(ee);
  if ~global_ref,
    ref_class= clInd*epo.y(clInd,ii);
  end
  if isfield(epo, 'yUnit') & isequal(epo.yUnit, 'dB'),
    epo.x(:,:,ii)= epo.x(:,:,ii) ./ epo_ref.x(:,:,ref_class);
  else
    epo.x(:,:,ii)= epo.x(:,:,ii) - epo_ref.x(:,:,ref_class);
  end
end

if global_ref,
  epo.className= strcat(epo.className, '-', epo_ref.className{1});
else
  epo.calssName= strcat(epo.className, '-', epo_ref.className);
end