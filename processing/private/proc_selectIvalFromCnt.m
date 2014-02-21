function [cnt, mrk]= proc_selectIval(cnt, mrk, ival)
%PROC_SELECTIVAL - Select subinterval from epoched or continuous data
%
%Synopsis:
% [CNT, MRK]= proc_selectIvalFromCnt(CNT, MRK, IVAL)
%
% Selects the time segment given by ival ([start_ms end_ms]). You may
% use inf as end_ms.
%
%Arguments:
% EPO,CNT - data structure of continuous (with markers MRK) or epoched data
% IVAL - time segment to be extracted
%  
%Returns:
% CNT,MRK  - updated data structures

ival_sa= round(ival*cnt.fs/1000);
if ival_sa(1)==0,
  ival_sa(1)= 1;
end
if isinf(ival_sa(2)),
  ival_sa(2)= size(cnt.x,1);
end

cnt.x= cnt.x(ival_sa(1):ival_sa(2),:);
idx_in_ival= find(mrk.time>ival(1) & mrk.time<=ival(2));
mrk.time= mrk.time - ival(1);
mrk= mrk_selectEvents(mrk, idx_in_ival);
