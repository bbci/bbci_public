function out= util_catIfNonequal(in, dim)

if length(in)==1,
  out= in{1};
  return;
end

iseq= zeros(1, length(in)-1);
for ii= 1:length(in)-1,
  iseq(ii)= isequal(in{1}, in{ii});
end
isnums= cellfun(@isnumeric,in);

if all(iseq),
  out= in{1};
else
  if all(isnums),
    if nargin<2,
      nd= cellfun(@ndims,in);
      sz= ones(max(nd), length(in));
      for ii= 1:length(in),
        sz(:,ii)= size(in{ii});
      end
      dim= find([max(sz,[],2); 1]==1, 1, 'first');
    end
    out= cat(dim, in{:});
  else
    out= in;
  end
end
