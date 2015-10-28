function [dat, W, A, lambda]= proc_spoc(dat, varargin)
% PROC_SPOC - Source Power Co-modulation Analysis (SPoC).
%
% Optimizes spatial filters such that the power of the filtered
% signal maximally covaries with the univariate target function, as
% described in Dahne et al., 2014a.
%
%
% References:
%
% S. Dahne, F. C. Meinecke, S. Haufe, J. Hohne, M. Tangermann, K. R. Muller, V. V. Nikulin, 
% "SPoC: a novel framework for relating the amplitude of neuronal
% oscillations to behaviorally relevant parameters",
% NeuroImage, 86(0):111-122, 2014


props= {'N_components'  'all'      'INT|CHAR'};

if nargin==0,
  dat = props; return
end

dat = misc_history(dat);
misc_checkType(dat, 'STRUCT(x clab y)'); 

opt = opt_proplistToStruct(varargin{:});
opt = opt_setDefaults(opt, props);
opt_checkProplist(opt, props);     

   
%% call to the actual spoc function

[W, A, lambda] = spoc(dat.x, dat.y);

[~, sort_idx] = sort(abs(lambda), 'descend');

if isnumeric(opt.N_components)
    sort_idx = sort_idx(1:opt.N_components);
end

W = W(:,sort_idx);
A = A(:,sort_idx);
lambda = lambda(sort_idx);


%% project the data onto the SPoC filters

dat = proc_linearDerivation(dat, W, 'prependix','spoc');

