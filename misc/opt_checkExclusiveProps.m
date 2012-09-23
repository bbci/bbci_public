function opt_checkExclusiveProps(opt, proppair, isdefault)


if ischar(opt),
  tag= ['in STRUCT ''' opt ''' '];
  opt= evalin('caller', opt);
else
  tag= '';
end

if nargin<3,
  for p= 1:size(proppair,1),
    for k= 1:length(opt),
      if ~isempty(opt(k).(proppair{p,1})) && ~isempty(opt(k).(proppair{p,2})),
        error('%sonly one of properties ''%s'' and ''%s'' can be nonempty.', ...
              tag, proppair{p,1}, proppair{p,2});
      end
    end
  end
else
  for p= 1:size(proppair,1),
    if ~isdefault.(proppair{p,1}) && ~isdefault.(proppair{p,2}),
      error('%sonly one of properties ''%s'' and ''%s'' can be set.', ...
            tag, proppair{p,1}, proppair{p,2});
    end
  end
end
