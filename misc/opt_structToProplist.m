function pl= opt_structToProplist(opt)
% OPT_STRUCTTOPROPLIST - Convert options struct into parameter/value list
%
% See also opt_proplistToStruct

if nargin==0 || isempty(opt)
  pl=[];
  return
end

C= cat(2, fieldnames(opt), struct2cell(opt))';
pl= C(:)';
