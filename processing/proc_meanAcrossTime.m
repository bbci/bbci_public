function epo= proc_meanAcrossTime(epo, ival, clab)
%PROC_MEANACROSSTIME - Average signals across a specified time interval
%
%Synopsis:
%  EPO= proc_meanAcrossTime(EPO, <IVAL>, <CLAB>)
%
%Arguments:
%  DAT  - data structure of epoched data
%  IVAL - interval in which the average is to be calculated,
%         default [] which means the whole time range
%  CLAB - cell array of channels to be selected, default all
%
%Returns:
%  DAT  - updated data structure


misc_checkType(epo, 'STRUCT(x)');
misc_checkTypeIfExists('ival', 'DOUBLE[2]');
misc_checkTypeIfExists('clab', 'CHAR|CELL{CHAR}');

if nargin<2,
  ival= [];
end
if nargin<3,
  clab= {};
end

if isempty(ival),
  idx= 1:size(epo.x,1);
else
  idx= util_timeind(epo, ival);
end
epo.x= mean(epo.x(idx,:,:), 1);
if isfield(epo, 't') && length(idx)>1,
  epo.t= mean(epo.t(idx(1:end-1)));
end

if ~isempty(clab),
  epo= proc_selectChannels(epo, clab);
end
