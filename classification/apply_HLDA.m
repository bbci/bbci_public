function out = apply_HLDA(XTr, C)
% APPLY_HLDA - Hierarchical linear discriminant analysis 
%
%Synopsis:
%   out = apply_HLDA(XTr, C)
% 
%Arguments:
%   XTR: DOUBLE [TxNxM] - Data matrix, with T temporal features, N
%                           N spatial features, and M 
%                           training points/examples. 
%   C: STRUCT           - a hierarchical LDA classifier structure that 
%                           contains the individual segment classifiers and 
%                           the top-level classifier. Must include the
%                           fields 'seg' and 'final'
%Returns:
%   out: FLOAT[]        - an array containing the classifier score for each 
%                           sample
%Description:
%   APPLY_HLDA applies a hierarchical LDA classifier given data and a
%   trained HLDA classifier.
%
%   References:Gerson, A.D., Parra, L.C., Sajda, P.: Cortically coupled 
%   computer vision for rapid image search. IEEE Transactions on Neural 
%   Systems and Rehabilitation Engineering 14, 174–179 (2006).
%
%Examples:
%   apply_HLDA(XTr, C))
%   
%See also:
%   TRAIN_HLDA

misc_checkType(XTr, 'DOUBLE');
misc_checkType(C, 'STRUCT(seg final)');


nSegments = length(C.seg);

dims = size(XTr);

%boundary indices between segments
seg_idx = round(linspace(0, dims(1), nSegments+1));

seg_scores = zeros(nSegments, dims(end));

for i = 1:nSegments
    seg = XTr(seg_idx(i) + 1 : seg_idx(i + 1), :, :); % i-th segment of X
    %apply LDA classifier for this segment
    seg = reshape(seg, [], dims(end));
    seg_scores(i,:) = apply_separatingHyperplane(C.seg(i), seg); %get classifier scores for segment
end

if isfield(C.final, 'B')
    %logistic regression as top-level classifier
    exps = C.final.B(1) + C.final.B(2:end)'*seg_scores;
    out = 1./(1 + exp(-exps));
    %transform scores to interval [-1 1]
    out = -2*(out - 0.5);
else
    %LDA as top-level classifier
    out = apply_separatingHyperplane(C.final, seg_scores);
end
