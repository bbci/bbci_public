function proj= procutil_biplist2projection(clab, bip_list)
% PROCUTIL_BIPLIST2PROJECTION -  Prepares a projection matrix for creating
% bipolar channels.
%Usage:
% proj = procutil_biplist2projection(clab, bip_list, <OPT>)
%
%Arguments:
% CLAB     [CELL ARRAY] - channel labels or struct containing a .clab field
% BIP_LIST [CELL ARRAY] - list specifying bipolar channels
%
%Example:
%
% % Creates new channels EOGh from F9-F10 and EOGv from EOGvu-Fp2
% procutil_biplist2projection(clab,{ {'F9' 'F10' 'EOGh'} {'EOGvu' 'Fp2' 'EOGv'})

misc_checkType(clab,'CELL|STRUCT');
misc_checkType(bip_list,'');


if isfield(clab, 'clab'),  %% if first argument is, e.g.,  cnt or epo struct
  clab= clab.clab;
end

proj = struct('chan',[],'filter',[]);
for bb= 1:length(bip_list),
  bip= bip_list{bb};
  proj(bb).chan= bip{1};
  proj(bb).filter= zeros(length(clab), 1);
  proj(bb).filter(util_chanind(clab, bip{1:2}))= [1 -1];
  proj(bb).new_clab= bip{3};
  proj(bb).rm_clab= {bip{1:2}};
end

[proj.clab]= deal(clab);
