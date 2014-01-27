function strout= util_untex(strin)
%strout= untex(strin)

if iscell(strin),
  strout= cellfun(@util_untex,strin,'UniformOutput',0);
  return
end

iSave= find(ismember(strin, '_^\%&#','legacy'));
strout= strin;
for is= iSave(end:-1:1),
  strout= [strout(1:is-1) '\' strout(is:end)];
end
