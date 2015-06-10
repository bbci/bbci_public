function out = apply_HLDA(epo, ival, C)
% TRAIN_LDA - linear discriminant analysis 
%
%Synopsis:
%   out = apply_HLDA(epo, ival, C)
% 
%Arguments:
%   epo: STRUCT         - Structure containing epoched ERP data, with
%                           obligatory fields 'x', 'y' and 't'.
%   ival: INT [2]       - interval of the ERP on which the training should be
%                           performed. Must match the
%                           size of the interval used to train the
%                           classifier C.
%   C: STRUCT           - a hierarchical LDA classifier structure that 
%                           contains the individual segment classifiers and 
%                           the top-level classifier. Must include the
%                           fields 'seg' and 'final'
%Returns:
%   out: FLOAT[]        - an array containing the classifier score for each 
%                           sample
%Description:
%   APPLY_HLDA applies a hierarchical LDA classifier given an epo structure,
%               a training interval and a number of segments
%
%Examples:
%   apply_HLDA(epo, ival, C))
%   
%See also:
%   TRAIN_HLDA

misc_checkType(epo, 'STRUCT(x y t)');
misc_checkType(ival, 'INT[2]');
misc_checkType(C, 'STRUCT(seg final)');


nSegments = length(C.seg);
dims = size(epo.x);
% convert interval values to indices
ival_idx = find(epo.t == ival(1)) : find(epo.t == ival(2));

% extract relevant interval from data
epo.x = epo.x(ival_idx, :, :);


dims = size(epo.x);

%boundary indices between segments
seg_idx = round(linspace(0, dims(1), nSegments+1));

seg_scores = zeros(nSegments, dims(end));

for i = 1:nSegments
    seg = epo.x(seg_idx(i) + 1 : seg_idx(i + 1), :, :); % i-th segment of X
    %apply LDA classifier for this segment
    seg = reshape(seg, [], dims(end));
    seg_scores(i,:) = apply_separatingHyperplane(C.seg(i), seg); %get classifier scores for segment
end

trial_scores = apply_separatingHyperplane(C.final, seg_scores);

out = trial_scores;
