function epo= proc_appendEpochs(epo1, epo2)
%PROC_APPENDEPOCHS - appends two or more structs of epoched data.
%
%Synopsis:
% EPO= proc_appendEpochs(EPO1, EPO2)
% EPO= proc_appendEpochs(EPOCELL)
%
%Arguments:
% EPOCELL         - cell array of epoched data
% EPO1, EPO2      - epoched data to be appended
%
%Returns:
% EPO             - appended epoched data
%
%Description:
% Appends the epochs of 'EPO2' to 'EPO1' (or appends all epochs of ERPCELL)
%
% SEE  proc_segmentation, mrk_mergerMarkers, proc_appendCnt,
%      proc_appendChannels

%epo1 = misc_history(epo1);

misc_checkType(epo1, 'STRUCT(x clab)|CELL{STRUCT}'); 
misc_checkTypeIfExists('epo2', 'STRUCT(x clab)');

if iscell(epo1),
  Cepo= epo1;
  epo1= Cepo{1};
  for ii= 2:length(Cepo),
    epo1= proc_appendEpochs(epo1, Cepo{ii});
  end
  epo=epo1;
  return
end
  
    
if isempty(epo1),
  epo= epo2;
  return;
elseif isempty(epo2),
  epo= epo1;
  return;
end


% begin sthf
if isfield(epo1, 'ndims')
  ndim = max(3, epo1.ndims);
else
  ndim = max(3, ndims(epo1.x));
end

if size(epo1.x,ndim-2)~=size(epo2.x,ndim-2),
  error('interval length mismatch');
end
if size(epo1.x,ndim-1)~=size(epo2.x,ndim-1),
  error('number of channels mismatch');
end
if ( ndim == 4 ) && ( size(epo1.x,ndim-3)~=size(epo2.x,ndim-3) ),
  error('number of frequencies mismatch');
end

epo= mrkutil_appendMarkersExcludingTime(epo1, epo2);
epo.x= cat(ndim, epo1.x, epo2.x);

% We could add functionality to struct_areFieldsEqual to return as second
% argument, which fields do not match. Then we could give here a more
% precise warning.
if ~struct_areFieldsEqual(epo1, epo2, {'fs','clab', 't'})
  warning('epochs are inconsistent wrt ''fs'', ''clab'', or ''t''.');
end
epo= struct_copyFields(epo, epo1, {'fs','clab','t'});

further_fields= {'xUnit', 'yUnit'};
for Fld= further_fields,
  if ~struct_areFieldsEqual(epo1, epo2, Fld)
    warning(sprintf('epochs are inconsistent wrt ''%s''.', Fld{1}));
  end
  epo= struct_copyFields(epo, epo1, Fld);
end

if isfield(epo1, 'mrk_info') && isfield(epo2, 'mrk_info'),
  epo.mrk_info= mrkutil_appendEventInfo(epo1.mrk_info, epo2.mrk_info);
end



% The following code should be superflutious in future
if isfield(epo1, 'p') && isfield(epo2, 'p') 
  epo.p= cat(ndim, epo1.p, epo2.p);
end
if isfield(epo1, 'sgnlogp') && isfield(epo2, 'sgnlogp') 
  epo.sgnlogp= cat(ndim, epo1.sgnlogp, epo2.sgnlogp);
end
if isfield(epo1, 'se') && isfield(epo2, 'se') 
  epo.se= cat(ndim, epo1.se, epo2.se);
end
if isfield(epo1, 'sigmask') && isfield(epo2, 'sigmask') 
  epo.sigmask= cat(ndim, epo1.sigmask, epo2.sigmask);
end
if isfield(epo1, 'crit') && isfield(epo2, 'crit')
  epo.crit= cat(1, epo1.crit, epo2.crit);
end
if isfield(epo1, 'df') && isfield(epo2, 'df')
  epo.df= cat(1, epo1.df, epo2.df);
end
