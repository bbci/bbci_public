function epo= proc_appendEpochs(epo, epo_append, mrk, mrk_append)
%PROC_APPENDEPOCHS - appends two or more epochs.
%
%Synopsis:
% epo= proc_appendEpochs(epo, epo_append, <mrk, mrk_append>)
% epo= proc_appendEpochs(epo_cell, <mrk_cell>)
%
%Arguments:
% epo             - epoched data or cell array of epochs
% epo_append      - epoched - data to be appended
% mrk, mrk_append - (optional) mrk structs needed to sort the data
%
%Returns:
% epo             - appended epoched data
%
%Description:
% appends the epochs of 'epo_append' to 'epo'
% if 'epo' is empty 'epo_append' is returned
% if mrk structures are given, epochs are sorted chronologically
% does NOT work for jittered epochs!!!
%
% SEE  makeEpochs, proc_appendCnt, proc_appendChannels
epo = misc_history(epo);

misc_checkType(epo, 'STRUCT(x clab)|CELL{STRUCT}'); 
misc_checkType(epo_append, 'STRUCT(x clab)');

if iscell(epo),
  Cepo= epo;
  epo= Cepo{1};
  if nargin>1,
    Cmrk= mrk;
    mrk= Cmrk{1};
    for ii= 2:length(Cepo),
      [epo, mrk]= proc_appendEpochs(epo, Cepo{ii}, mrk, Cmrk{ii});
    end
  else
    for ii= 2:length(Cepo),
      epo= proc_appendEpochs(epo, Cepo{ii});
    end
  end
  return
end
  
    
if isempty(epo),
  epo= epo_append;
  return;
end

% begin sthf
if isfield(epo, 'ndims')
  ndims = max(3, epo.ndims);
else
  ndims = max(3, length(size(epo.x)));
end

if size(epo.x,ndims-2)~=size(epo_append.x,ndims-2),
  error('interval length mismatch');
end
if size(epo.x,ndims-1)~=size(epo_append.x,ndims-1),
  error('number of channels mismatch');
end
if ndims == 4
  if size(epo.x,ndims-3)~=size(epo_append.x,ndims-3),
    error('number of frequencies mismatch');
  end
end

epo.x= cat(ndims, epo.x, epo_append.x);
if isfield(epo, 'p') && isfield(epo_append, 'p') 
  epo.p= cat(ndims, epo.p, epo_append.p);
end
if isfield(epo, 'sgnlogp') && isfield(epo_append, 'sgnlogp') 
  epo.sgnlogp= cat(ndims, epo.sgnlogp, epo_append.sgnlogp);
end
if isfield(epo, 'se') && isfield(epo_append, 'se') 
  epo.se= cat(ndims, epo.se, epo_append.se);
end
if isfield(epo, 'sigmask') && isfield(epo_append, 'sigmask') 
  epo.sigmask= cat(ndims, epo.sigmask, epo_append.sigmask);
end
if isfield(epo, 't') && isfield(epo_append, 't')
  epo.t= cat(ndims, epo.t, epo_append.t);
end
if isfield(epo, 'crit') && isfield(epo_append, 'crit')
  epo.crit= cat(1, epo.crit, epo_append.crit);
end
if isfield(epo, 'df') && isfield(epo_append, 'df')
  epo.df= cat(1, epo.df, epo_append.df);
end

epo.y= cat(2, epo.y, zeros(size(epo.y,1),size(epo_append.y,2)));
fie = {};

if isfield(epo, 'indexedByEpochs') & isfield(epo_append, 'indexedByEpochs'),
  idxFields= intersect(epo.indexedByEpochs, epo_append.indexedByEpochs,'legacy');
  for Fld= idxFields,
    fld= Fld{1};
    tmp= getfield(epo, fld);
    sz= size(tmp);
    fie = {fie{:},fld};
    eval(sprintf('epo.%s= cat(length(sz), tmp, epo_append.%s);', ...
                 fld, fld));
  end
end

if sum(strcmp(fie,'jit'))==0 & (isfield(epo, 'jit') | isfield(epo_append, 'jit')),
  if ~isfield(epo, 'jit'), 
    epo.jit= zeros(1, size(epo.y,2));
  end
  if ~isfield(epo_append, 'jit'), 
    epo_append.jit= zeros(1, size(epo_append.y,2));
  end
  epo.jit= cat(2, epo.jit, epo_append.jit);
end

if sum(strcmp(fie,'bidx'))==0 & (isfield(epo, 'bidx') | isfield(epo_append, 'bidx')),
  if ~isfield(epo, 'bidx'), 
    epo.bidx= 1:size(epo.y,2); 
  end
  if ~isfield(epo_append, 'bidx'), 
    epo_append.bidx= size(epo.y,2)+1:size(epo.y,2)+size(epo_append.y,2); 
  end
  epo.bidx= cat(2, epo.bidx, epo_append.bidx);
end
  
if isfield(epo, 'className') & isfield(epo_append, 'className'),
  for i = 1:length(epo_append.className)
    c = find(strcmp(epo.className,epo_append.className{i}));
    if isempty(c)  
      epo.y= cat(1, epo.y, zeros(1,size(epo.y,2)));
      epo.className=  cat(2, epo.className, {epo_append.className{i}});
      c= size(epo.y,1);
    elseif length(c)>1,
      error('multiple classes have the same name');
    end
    epo.y(c,end-size(epo_append.y,2)+1:end) = epo_append.y(i,:);
  end
end

if exist('mrk_append', 'var'),
  [si,si]= sort([mrk.pos+epo.t(end) mrk_append.pos+epo_append.t(end)]);
  if isfield(epo, 'bidx'),
    error('not implemented');
  end
% begin sthf
  subind ='';
  for isi = 1:ndims-1
    subind = [subind ':,'];
  end
  epo.x= eval(['epo.x(' subind 'si);']);
% end sthf  
  epo.y= epo.y(:,si);
end
