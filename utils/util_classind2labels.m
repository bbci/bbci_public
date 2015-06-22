function y= util_classind2labels(idx)

nClasses= max(idx);
y = [1:nClasses]'*ones(1,length(idx)) == ones(nClasses,1)*idx(:)' ;
