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
%                   
% OUT LOSS  - vector of loss values
%
% SEE crossvalidation

% Benjamin Blankertz
% schultze-kraft@tu-berlin.de


nClasses= size(label, 1);

% convert classifier output to estimated labels
sz= size(out);
est= zeros([1 sz(2:end)]);
est(:,:)= 1.5 + 0.5*sign(out(:,:));
est= permute(est, [3 2 1]);

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

loss_matrix= (sum(N)./N)/nClasses * ones(1,nClasses);
loss_matrix= loss_matrix - diag(diag(loss_matrix));

loss= loss_matrix(sub2ind([nClasses nClasses], lind, est));
