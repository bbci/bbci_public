function loss= loss_0_1(label, out)
%LOSS_0_1 - Loss function: assigning 0 (correct) and 1 (error) to each sample
%
%Synopsis:
% LOSS= loss_0_1(LABEL, OUT)
%
%Arguments:
% LABEL - matrix of true class labels, size [nClasses nSamples]
% OUT   - matrix (or vector for 2-class problems) of classifier outputs
%
%Returns:
% LOSS  - vector of 0-1 loss values
%
% SEE crossvalidation

% Benjamin Blankertz


lind= [1:size(label,1)]*label;
if size(out,1)==1,
  est= 1.5 + 0.5*sign(out);
else
  [dmy, est]= max(out, [], 1);
end

loss= est~=lind;
