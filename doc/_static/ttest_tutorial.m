% T-test tutorial

% Generate some toy data
N = 20;
d = [randn(N,1) randn(N,1)+0.7];      % Each column is one dataset

% Paired-samples t-test
[h,p,ci,stats] = ttest(d(:,1), d(:,2)); 

% Format output
if h
  fprintf('There was a significant effect of FACTOR (t(%d) = %2.2f, p = %0.2f).\n', ...
    stats.df,stats.tstat,p)
else
  fprintf('There was no significant effect of FACTOR (p = %0.2f).\n',p)
end

% Independent samples t-test
[h,p,ci,stats] = ttest2(d(:,1), d(:,2))