function loss= loss_classwiseNormalized(label, out, N)
%LOSS_CLASSWISENORMALIZED - Loss function with weightinh for unbalanced
%classes
%
%Synopsis:
% LOSS= loss_classwiseNormalized(LABEL, OUT)
% LOSS= loss_classwiseNormalized(LABEL, OUT, N)
%
% IN  LABEL - matrix of true class labels, size [nClasses nSamples]
%     OUT   - vector of classifier outputs
%     N     - vector of length nClasses, the i-th element specifying the
%             number of samples contained in class i in the whole database
%             (only the ratio N/sum(N) is relevant)
%                   
% OUT LOSS  - vector of loss values
%
% SEE crossvalidation

% Benjamin Blankertz
% schultze-kraft@tu-berlin.de


nClasses= size(label, 1);

est= util_cfyoutput2labels(out);
lind= (1:nClasses)*label;

if nargin<3 || isempty(N),
  % this estimates class sizes on the validation set
  N= sum(label, 2);
else
  N= reshape(N, [nClasses 1]);
end

if any(not(N)) % problem when any(N==0)
  error(sprintf('%s is only applicable if both classes are represented.',mfilename))
end
if min(N)<7,
  msg= sprintf('Smallest class has only %d test samples - results may be unreliable. Consider providing the actual ratio as argument to %s.', ...
               min(N), mfilename);
  util_warning(msg, 'loss', 'Interval',60);
end

loss_matrix= (sum(N)./N)/nClasses * ones(1,nClasses);
loss_matrix= loss_matrix - diag(diag(loss_matrix));

loss= loss_matrix(sub2ind([nClasses nClasses], lind, est));
