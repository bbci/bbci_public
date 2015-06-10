function C = train_HLDA(epo, ival, nSegments)
% TRAIN_LDA - Hierarchical linear discriminant analysis 
%
%Synopsis:
%   C = train_HLDA(epo, ival, nSegments)
%
%Arguments:
%   epo: STRUCT         - Structure containing epoched ERP data, with
%                           obligatory fields 'x', 'y' and 't'.
%   ival: INT [2]       - interval of the ERP on which the training should be
%                           performed
%   num_segments: INT   - the number of non-overlapping segments the interval
%                           should be separated in  
%Returns:
%   C: STRUCT           - Structure containing the trained classifiers for
%                           each segment and the final top level
%                           classifier. The structure C includes the fields:
%       'seg': STRUCT []    - contains a trained LDA classifier for each segment
%       'final': STRUCT     - the final top-level LDA classifier
%Description:
%   TRAIN_HLDA trains a hierarchical LDA classifier given an epo structure,
%               a training interval and a number of segments
%
%Examples:
%   train_HLDA(epo, ival, num_segments)
%   
%See also:
%   APPLY_HLDA

misc_checkType(epo, 'STRUCT(x y t)');
misc_checkType(ival, 'INT[2]');
misc_checkType(nSegments, 'INT');

if isempty(ival)
    ival = [epo.t(1), epo.t(end)];
end
% convert interval values to indices
ival_idx = find(epo.t == ival(1)) : find(epo.t == ival(2));

% extract relevant interval from data
epo.x = epo.x(ival_idx, :, :);
epo.t = epo.t(ival_idx);

dims = size(epo.x);

%boundary indices between segments
seg_idx = round(linspace(0, dims(1), nSegments+1));

seg_scores = zeros(nSegments, dims(end));

for i = 1:nSegments
    seg = epo.x(seg_idx(i) + 1 : seg_idx(i + 1), :, :); % i-th segment of X
    %train LDA classifier for this segment
    seg = reshape(seg, [], dims(end));
    seg_LDA = train_RLDAshrink(seg, epo.y, 'Scaling', 1);
    C.seg(i) = seg_LDA; 
    seg_scores(i,:) = apply_separatingHyperplane(seg_LDA, seg); %get classifier scores for segment
end

scores_LDA = train_RLDAshrink(seg_scores, epo.y, 'Scaling', 1);
%trial_scores = apply_separatingHyperplane(scores_LDA, seg_scores);

C.final = scores_LDA;