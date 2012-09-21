function yesorno= struct_areFieldsEqual(s1, s2, varargin)
%STRUCT_AREFIELDSEQUAL - Tests whether two struct are equal wrt specified fields
%
%Synopsis:
%  YESORNO= struct_areFieldsEqual(S1, S2, FLDS)
%  YESORNO= struct_areFieldsEqual({S1, S2}, FLDS)


if length(varargin)==1 && iscell(varargin{1}),
  fieldpatterns= varargin{1};
else
  fieldpatterns= varargin;
end
s1f= fieldnames(s1);
idx= str_patternMatch(fieldpatterns, s1f);
fieldlist= s1f(idx);
founddiff= 0;
for i= 1:length(fieldlist),
  fld= fieldlist{i};
  founddiff= founddiff | xor(isfield(s1, fld), isfield(s2, fld));
  if isfield(s1, fld) && isfield(s2, fld),
    founddiff= founddiff | (~isequal(getfield(s1,fld), getfield(s2,fld)));
  end
end
yesorno= ~founddiff;
