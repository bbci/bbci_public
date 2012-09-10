function opt_checkExclusiveProps(opt, proppair, isdefault)


if ischar(opt),
  tag= ['in STRUCT ''' opt ''' '];
  opt= evalin('caller', opt);
else
  tag= '';
end

if nargin<3,
  for k= 1:size(proppair,1),
    if ~isempty(opt.(proppair{k,1})) && ~isempty(opt.(proppair{k,2})),
      error('%sonly one of properties ''%s'' and ''%s'' can be nonempty.', ...
            tag, proppair{k,1}, proppair{k,2});
    end
  end
else
  for k= 1:size(proppair,1),
    if ~isdefault.(proppair{k,1}) && ~isdefault.(proppair{k,2}),
      error('%sonly one of properties ''%s'' and ''%s'' can be set.', ...
            tag, proppair{k,1}, proppair{k,2});
    end
  end
end
