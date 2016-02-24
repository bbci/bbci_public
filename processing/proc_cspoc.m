function [dat, W, A, r_values] = proc_cspoc(dat, maxmin_flag, varargin)
% PROC_CSPOC - Canonical Source Power Co-modulation Analysis (cSPoC)
%
% Optimizes spatial filters such that the power of the filtered signals are
% maximally positively (or negatively) correlated. The function can be used
% in two ways:
% (1) The data of a single subject are bandpass filtered in multiple
% frequency bands, using the function proc_filterbank
% (2) The data of multiple subjects are bandpass filtered in a single
% frequency band
%
%Synopsis:
% [DAT, SPOC_W, SPOC_A, R_VALUES]= proc_cspoc(DAT, MINMAX_FLAG, <OPT>)
%
%Arguments:
% DAT         - either a data structure of epoched data of one subject,
%               containing multiband filtered channels (obtained via
%               proc_filterbank), or a cell array, each cell containing a
%               data structure of epoched data that has been multiband
%               filtered
% MINMAX_FLAG - either 1 for maximizing or -1 for minimizing correlation
% OPT         - struct or property/value list of optional properties:
%  .nComponentPairs   - either the string 'all' or an integer, determining
%                       the number of components pairs to be returned,
%                       default: 'all'
%  .nRepeats          - number of re-starts per component pair, default: 10
%  .maxIter           - maximum number of optimizer iterations, default: 200
%  .averageOverEpochs - when optimizing the correlations, average the
%                       source envelopes within epochs, default: false
%
%Returns:
% DAT    - updated data structure
% SPOC_W  - SPOC projection matrix (spatial filters, in the columns)
% SPOC_A  - estimated mixing matrix (activation patterns, in the columns)
% LAMBDA - eigenvalue score of SPOC projections 

props= {'nComponentPairs'       'all'       'STRING|DOUBLE[1]'
        'nRepeats'              10          'DOUBLE[1]'
        'averageOverEpochs'     0           'BOOLE'
        'maxIter'               200         'DOUBLE[1]'
       };

if nargin==0,
  dat = props; return
end

dat = misc_history(dat);
misc_checkType(dat, 'STRUCT(x clab y)|CELL');

opt = opt_proplistToStruct(varargin{:});
opt = opt_setDefaults(opt, props);
opt_checkProplist(opt, props);

%% contruct data cells
% cSPoC is performed on one multi bandpass filtered data set
if not(iscell(dat))
    % check that all clabs contain the string 'flt'
    if any(cellfun(@(x) isempty(x),cellfun(@(x) strfind(x,'flt'),dat.clab,'UniformOutput',0)))
        error('data are not band-pass filtered by proc_filterbank')
    end
    N = length(unique(str2mat(cellfun(@(x) x(end),dat.clab)')));
    X = cell(1,N);
    for ii = 1:N
        dat2 = proc_selectChannels(dat,sprintf('*flt%d',ii));
        X{ii} = dat2.x;
    end
% cSPoC is performed on multiple single bandpass filtered data sets
else
    N = length(dat);
    X = cell(1,N);
    for ii = 1:N
        X{ii} = dat{ii}.x;
    end
end
   
%% run cSPoC
opt = renameStructField(opt,'nComponentPairs','n_component_sets');
opt = renameStructField(opt,'nRepeats','n_repeats');
opt = renameStructField(opt,'averageOverEpochs','average_over_epochs');

[W,A,r_values] = cspoc(X,maxmin_flag,opt);

%% project the data onto cSPoC filters
datnew = [];
for ii = 1:N
    if not(iscell(dat))
        dat2 = proc_selectChannels(dat,sprintf('*flt%d',ii));
    else
        dat2 = dat{ii};
    end
    dat2 = proc_linearDerivation(dat2,W{ii},'prependix',sprintf('cspoc%d_',ii));
    datnew = proc_appendChannels(datnew,dat2);
end

dat = datnew;
