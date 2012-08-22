function epo= proc_selectEpochs(epo, idx, varargin)
%PROC_SELETEPOCHS - Select specified epochs within epoch structure
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
epo= misc_history(epo);


props= {'RemoveVoidClasses',   1,   'BOOL'};

if nargin==0,
  epo= props; return
end

misc_checkType(epo, 'STRUCT(x clab fs)');

if mod(length(varargin),2)==1,
  if isequal(idx, 'not'),
    idx= setdiff(1:size(epo.y,2), varargin{1});
    varargin= varargin(2:end);
  else
    error('if 3rd argument is given, the 2nd must be ''not''');
  end
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
  if length(nonvoidClasses)<size(epo.y,1) && opt.removevoidclasses
    msg= sprintf('void classes removed, %d classes remaining', ...
                 length(nonvoidClasses));
    bbci_warning(msg, 'selection', mfilename);
    epo.y= epo.y(nonvoidClasses,:);
    if isfield(epo, 'className'),
      epo.className= {epo.className{nonvoidClasses}};
    end
  end
end

if isfield(epo, 'event'),
  for Fld= fieldnames(epo.event),
    fld= Fld{1};
    tmp= getfield(epo, fld);
    subidx= cat(2, repmat({':'}, 1, ndims(tmp)-1), {idx});
    epo.event= setfield(epo.event, fld, tmp(subidx{:}));
  end
end
