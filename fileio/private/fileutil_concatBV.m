function [varargout]= fileutil_concatBV(file_list, varargin)
% FILEUTIL_CONCATBV - concatenate files which are stored in BrainVision format
%
% Synopsis:
%   [DAT, MRK, MNT]= fileutil_concatBV(FILE_LIST, 'Property, 'Value', ...)
%
% Arguments:
%   FILE_LIST: list of file names (no extension)
%
% Returns:
%   DAT: structure of continuous or epoched signals
%   MRK: marker structure
%   MNT: electrode montage structure
%
% Properties:
%   are passed to file_loadBV
%
% Description:
%   This function is called by file_loadBV in case the file name argument
%   is a cell array of file names. Typically there is no need to call this 
%   function directly.
%
%

if ~iscell(file_list),
  file_list= {file_list};
end

T= zeros(1, length(file_list));
dataOffset = 0;
for ii= 1:length(file_list),
  [cnt, mrk, hdr]= file_loadBV(file_list{ii}, varargin{:});
  T(ii)= size(cnt.x,1);
  if ii==1,
    ccnt= cnt;
    curmrk= mrk;
  else
    if ~isequal(cnt.clab, ccnt.clab),
      warning(['inconsistent clab structure will be repaired ' ...
               'by using the intersection']); 
      commonclab= intersect(cnt.clab, ccnt.clab);
      cnt= proc_selectChannels(cnt, commonclab{:});
      ccnt= proc_selectChannels(ccnt, commonclab{:});
    end
    if ~isequal(cnt.fs, ccnt.fs)
        error('inconsistent sampling rate'); 
    end
    ccnt.x= cat(1, ccnt.x, cnt.x);
    
    mrk.time= mrk.time + dataOffset*1000/cnt.fs;
    
%     % find markers in the loaded interval
%     inival= find(curmrk.time > skip*1000/cnt.fs & ...
%         curmrk.time <= (skip+maxlen)*1000/cnt.fs);
%     curmrk= mrk_selectEvents(curmrk, inival);
%     %let the markers start at zero
%     curmrk.time= curmrk.time - skip*1000/cnt.fs;
    
    curmrk = mrk_mergeMarkers(curmrk, mrk);
    
  end
  dataOffset = dataOffset + T(ii);

end

ccnt.T= T;
if length(file_list)>1,
  ccnt.title= [ccnt.title ' et al.'];
  ccnt.file= strcat(fileparts(ccnt.file), file_list);
end

varargout= cell(1, nargout);
varargout{1}= ccnt;
if nargout>1,
  varargout{2}= curmrk;
  if nargout>2,
    varargout{3}= hdr;
  end
end
