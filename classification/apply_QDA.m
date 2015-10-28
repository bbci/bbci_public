function out = apply_QDA(C, y)
%APPLY_QDA - Apply quadratic classifier to features
%
%Synopsis:
%  OUT= apply_QDA(C, Y)
%
%Arguments:
%  C  - STRUCT with fields 'w', 'b' and 'sq'
%  Y  - DOUBLE [nDim nSamples]
%
%Returns:
%  OUT  - Classifier output


out = real( C.w'*y + repmat(C.b,1,size(y,2)) );
if size(out,1)==1
    out = out + sum(y.*(C.sq*y));
else
    for i = 1:size(out,1)
        out(i,:) = out(i,:) + sum(y.*(C.sq(:,:,i)*y));
    end
end