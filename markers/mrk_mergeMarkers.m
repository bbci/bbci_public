function mrk= mrk_mergeMarkers(mrk1, mrk2, varargin)
%MRK_MERGEMARKERS - Merge Marker Structs
%
%Description:
% This function merges two or more marker structs into one.
%
%Synopsis:
% MRK= mrk_mergeMarkers(MRK1, MRK2, ...)


misc_checkType(mrk1, 'STRUCT(time)');
misc_checkType(mrk2, 'STRUCT(time)');

if isempty(mrk1),
  mrk= mrk2;
  return;
elseif isempty(mrk2),
  mrk= mrk1;
  return;
end

mrk= mrkutil_appendEventInfo(mrk1, mrk2);
mrk.time= cat(1, mrk1.time(:), mrk2.time(:))';

%% Recursion
if length(varargin)>0,
  mrk= mrk_mergeMarkers(mrk, varargin{1}, varargin{2:end});
end
