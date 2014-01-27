function s1= struct_sloppycat(s1, s2, varargin)
% STRUCT_SLOPPYCAT - Copy fields 
%
% Synopsis:
%   s1= file_loadMatlab(s1,s2,<OPT>)
%
%Arguments:
%   S1:     STRUCT - target struct in which fields from s2 are copied
%   S2:     STRUCT
%   OPT: PROPLIST - Structure or property/value list of optional properties:
%     'Dim' - INT (default 2): ?
%     'Keepfields' - 
%     'Matchsize' - 
%
% See also: struct_copyFields


props = {'Dim',         2           '!INT[1]';
         'Keepfields'   3           '!INT[1]|!CHAR(none first last all)';
         'Matchsize'    0           '!BOOL';
         };

if nargin==0
    s1=props;return
end
     
if isempty(s1),
  s1= s2;
  return;
elseif isempty(s2),
  return;
end

opt= opt_proplistToStruct(varargin{:});
[opt, isdefault]= opt_setDefaults(opt, props);
opt_checkProplist(opt, props);
misc_checkType(s1,'STRUCT');
misc_checkType(s2,'STRUCT');

flds1= fieldnames(s1);
flds2= fieldnames(s2);

switch(opt.Keepfields),
 case {0,'none'},
  flds= intersect(flds1, flds2,'legacy');
  s1= rmfield(s1, setdiff(flds1, flds,'legacy'));
  s2= rmfield(s2, setdiff(flds2, flds,'legacy'));
 case {1,'first'},
  flds= flds1;
  if opt.Matchsize,
    s2= struct_createfields(s2, setdiff(flds, flds2,'legacy'), 'matchsize',s1(1));
  else
    s2= struct_createfields(s2, setdiff(flds, flds2,'legacy'));
  end
 case {2,'last'},
  flds= flds2;
  if opt.Matchsize,
    s1= struct_createfields(s1, setdiff(flds, flds1,'legacy'), 'matchsize',s2(1));
  else
    s1= struct_createfields(s1, setdiff(flds, flds1,'legacy'));
  end
 case {3,'all'},
  flds= union(flds1, flds2,'legacy');
  if opt.Matchsize,
    s1= struct_createfields(s1, setdiff(flds, flds1,'legacy'), 'matchsize',s2(1));
    s2= struct_createfields(s2, setdiff(flds, flds2,'legacy'), 'matchsize',s1(1));
  else
    s1= struct_createfields(s1, setdiff(flds, flds1,'legacy'));
    s2= struct_createfields(s2, setdiff(flds, flds2,'legacy'));
  end
 otherwise
  error('unknown value for OPT.Keepfields');
end

s1= cat(opt.Dim, s1, s2);
