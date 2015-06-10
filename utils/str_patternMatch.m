function ind= str_patternMatch(pats, strs)
%STR_PATTERNMATCH
%
%Synopsis:
% IDX= str_patternMatch(PATS, STRS)
%
% IN  PATS - pattern (string) or patterns (cell array of strings)
%            which may include the wildcard '*' and other regular
%            expressions, see regexp.
%
%     STRS - cell array of strings (or just a string)
%
% OUT IDX  - indices of those strings which are matched by the
%            (resp. by any of the) pattern(s).


if ~iscell(pats), pats= {pats}; end
if ~iscell(strs), strs= {strs}; end

ind= [];
for pp= 1:length(pats),
%   pat= strrep(pats{pp}, '*', '.*');
  pat= ['^' strrep(pats{pp}, '*', '.*') '$'];
  thismatch= cellfun(@(x)(~isempty(x)), regexpi(strs, pat));
  if pp==1,
    ismatch= thismatch;
  else
    ismatch= ismatch | thismatch;
  end
end
ind= find(ismatch);
