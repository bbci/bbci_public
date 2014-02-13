function epo= proc_selectEpochs(epo, idx, varargin)
%PROC_SELECTEPOCHS - Select specified epochs within epoch structure
%
%Synopsis:
%  EPO= proc_selectEpochs(EPO, IDX, <OPT>)
%  EPO= proc_selectEpochs(EPO, 'not', IDX, <OPT>)
%
%Arguments:
%  EPO: STRUCT - Epoch structure
% selects the epochs with specified indices. void classes are removed.
%
% the structure 'epo' may contain a field 'indexedByEpochs' being a
% cell array of field names of epo. in this case subarrays of those
% fields are selected. here it is assumed that the last dimension
% is indexed by epochs.
%
% IN  epo  - structure of epoched data
%     idx  - indices of epochs that are to be selected [or are to be
%            excluded if the 'not' form is used].
%            if this argument is omitted, all non-rejected epochs are
%            selected, i.e., epochs with any(epo.y).
%
% OUT epo  - updated data structure

% Benjamin Blankertz
props= {'RemoveVoidClasses',   1,   'BOOL'};

if nargin==0,
  epo= props; return
end

misc_checkType(epo, 'STRUCT(x clab)');
epo= misc_history(epo);

if isequal(idx, 'not'),
  idx= setdiff(1:size(epo.y,2), varargin{1},'legacy');
  varargin= varargin(2:end);
end

opt= opt_proplistToStruct(varargin{:});
opt= opt_setDefaults(opt, props);

if ~exist('idx','var'),
  %% select accepted epochs
  idx= find(any(epo.y==1,1));
end

subidx= cat(2, repmat({':'}, 1, ndims(epo.x)-1), {idx});
epo.x= epo.x(subidx{:});

if isfield(epo, 'y'),
  epo.y= epo.y(:,idx);

  nonvoidClasses= find(any(epo.y==1,2));
  if length(nonvoidClasses)<size(epo.y,1) && opt.RemoveVoidClasses
    msg= sprintf('void classes removed, %d classes remaining', ...
                 length(nonvoidClasses));
    warning(msg, 'selection', mfilename);
    epo.y= epo.y(nonvoidClasses,:);
    if isfield(epo, 'className'),
      epo.className= {epo.className{nonvoidClasses}};
    end
  end
end

if isfield(epo, 'event'),
  for Fld= fieldnames(epo.event)',
    fld= Fld{1};
    tmp= getfield(epo.event, fld);
    % the first dimension must be indexed by epochs
    subidx= repmat({':'}, 1, ndims(tmp));
    subidx{1}= idx;
    epo.event= setfield(epo.event, fld, tmp(subidx{:}));
  end
end
