function hsp= gridutil_getSubplots(chans)
%GRIDUTIL_GETSUBPLOTS - Returns the handles of the subplots of a grid plot
% that correspond to given channels
%
%Synposis:
% HSP= gridutil_getSubplots(<CHANS>)
%
%Input:
% CHANS: channel indices, [] means all, default []

if ~exist('chans','var'), chans=[]; end
if ~isempty(chans) && ~iscell(chans),
  chans= {chans};
end

if ~isempty(chans) && ischar(chans{1}) && ...
      strcmp(chans{1},'plus'),
  search_type= '^ERP';   % starting with 'ERP'
  chans= chans(2:end); 
else
  search_type= '^ERP$';  % only the word 'ERP'
end

hc= get(gcf, 'children');
isERPplot= zeros(size(hc));

for ih= 1:length(hc),
  ud= get(hc(ih), 'userData');
  if isstruct(ud) && isfield(ud,'type') && ischar(ud.type) && ...
        ~isempty(regexp(ud.type,search_type))
    if isempty(chans) || ~isempty(util_chanind(ud.chan,chans)),
      isERPplot(ih)= 1;
    end
  end
end

hsp= hc(find(isERPplot))';
