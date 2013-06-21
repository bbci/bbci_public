function T= opt_substruct(S, fld_list)
%OPT_SUBSTRUCT - Create substruct of specified fields
%
%Synopsis:
%  T= opt_substruct(S, <FLD_LIST>)
%
%Arguments:
%  S:  STRUCT - Source, from which fields are taken
%  FLD_LIST: CELL of CHAR - Names of the fields that should be copied from
%      S into the newly generated substruct T
%
%Returns:
%  T: STRUCT - Substruct of S with specified fields


% Let us be gracious:
if ischar(fld_list),
  fld_list= {fld_list};
end

fld_list= intersect(lower(fld_list), lower(fieldnames(S)));
T= [];
for ii= 1:length(fld_list),
  fld= fld_list{ii};
  [T.(fld)]= S.(fld);
end
