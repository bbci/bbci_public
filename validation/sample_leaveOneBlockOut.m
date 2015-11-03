function [divTr, divTe] = sample_leaveOneBlockOut(label, block_idx, strat)
%SAMPLE_LEAVEONEBLOCKOUT - Sampling function: block divisions
%
%Synopsis:
%  [DIVTR, DIVTE] = sample_leaveOneBlockOut(LABEL, BLOCK_IDX, <STRAT>)
%
%Arguments:
% LABEL     - Despensable input argument, required for compability reasons
% BLOCK_IDX - [1 x nSamples] array of indices which defines to which block
%             each sample belongs. This can be e.g. mrk.blkno, when mrk is
%             obtained from mrk_evenlyInBlocks
% STRAT     - [1 x 2] bool indicating to stratify the samples by
%             performing a random sampling on the training and/or test
%             sets, default [0 0]
%
%Returns: 
% DIVTR     - Partitions of the training set
% DIVTE     - Partitions of the test set

% 2015-11 Matthias Schultze-Kraft

if nargin<3
    strat = [0 0];
end

divTr = cell(1, 1);
divTe = cell(1, 1);
idx_list = unique(block_idx);
for nn = 1:length(idx_list)
    % test set indices
    idx = find(block_idx==idx_list(nn));
    if strat(2)
        idx = stratify(idx,label);
    end
    divTe{1}(nn) = {idx};
    % training set indices
    idx = find(block_idx~=idx_list(nn));
    if strat(1)
        idx = stratify(idx,label);
    end
    divTr{1}(nn) = {idx};    
end

function idx = stratify(idx,label)
idx = {idx(logical(label(1,idx))) idx(logical(label(2,idx)))};
Nmin = min([length(idx{1}) length(idx{2})]);
if Nmin==0
    warning('No stratification performed because the number of samples of one class is zero.')
else
    [Nmax,ci] = max([length(idx{1}) length(idx{2})]);
    ri = randperm(Nmax,Nmin);
    idx{ci} = idx{ci}(ri);
end
idx = [idx{:}];
