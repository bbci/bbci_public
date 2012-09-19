function str= bbciutil_strrepGlobals(str, replace_list)

if nargin<2,
  replace_list= {'BBCI.Tp.Dir', 'BBCI.Tp.Code', 'BBCI.TmpDir'};
end

eval(['global ' sprintf('%s ', replace_list{:})]);
for k= 1:length(replace_list),
  name= replace_list{k};
  if isempty(eval(name)),
    if ~isempty(strfind(['$' name], str)),
      error(sprintf('string contains ''$%s'', but this global variable is undefined', name));
    end
  else
    str= strrep(str, ['$' name], eval(name));
  end
end
