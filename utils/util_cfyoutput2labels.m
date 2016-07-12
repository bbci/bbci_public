function labels= util_cfyoutput2labels(out)
%UTIL_CFYOUTPUT2LABELS - Convert classifier outputs to estimated class labels
%
%Synopsis:
%  LABELS= util_cfyoutput2labels(OUT)
%
%Arguments:
%  OUT  - classifier output, the format can either be
%         (1) [nClasses nSamples] where each entry in one column reflects
%         membership (e.g. as probability), or
%         (2) [1 nSamples] (two-class cases only) where negative values
%         represent class 1 and positive values represent class 2.
%
%Returns:
%  LABELS - estimated labels

sz= size(out);
labels= zeros([1 sz(2:end)]);
if size(out,1)==1,
  labels(:,:)= 1.5 + 0.5*sign(out(:,:));
else
  [dummy, labels(:,:)]= max(out(:,:));
end

labels= permute(labels, [3 2 1]);
