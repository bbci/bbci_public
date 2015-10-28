function out= proc_average(epo, varargin)
%PROC_AVERAGE - Classwise calculated averages
%
%Synopsis:
% EPO= proc_average(EPO, <OPT>)
% EPO= proc_average(EPO, CLASSES)
%
%Arguments:
% EPO -      data structure of epoched data
%            (can handle more than 3-dimensional data, the average is
%            calculated across the last dimension)
% OPT struct or property/value list of optional arguments:
%  .Policy - 'mean' (default), 'nanmean', or 'median'
%  .Std    - if true, standard deviation is calculated also 
%  .Stats  - if true, additional statistics are calculated, including the
%            standard error of the mean, the t score, the p-value for the null 
%            Hypothesis that the mean is zero, and the "signed log p-value"
%  .Classes - classes of which the average is to be calculated,
%            names of classes (strings in a cell array), or 'ALL' (default)
% 'Bonferroni' - if true, Bonferroni corrected is used to adjust p-values
%                and their logarithms
% 'Alphalevel' - if provided, a binary indicator of the significance to the
%                alpha level is returned for each feature in fv_rval.sigmask
%
% For compatibility PROC_AVERAGE can be called in the old format with CLASSES
% as second argument (which is now set via opt.Classes):
% CLASSES - classes of which the average is to be calculated,
%           names of classes (strings in a cell array), or 'ALL' (default)
%
%Returns:
% EPO     - updated data structure with fields
%  .x     - classwise means
%  .N     - vector of epochs per class across which average was calculated
%  .std   - standard deviation, if requested (opt.Std==1), format as epo.x
%  .se    - contains the standard error of the mean, if opt.Stats==1
%  .tstat     - Student t statistics of the difference, if opt.Stats==1
%  .df    - degrees of freedom of the t distribution (one sample test)
%  .p     - p value of null hypothesis that the mean is zero, 
%           derived from t Statistics using two-sided test, if opt.Stats==1
%           If opt.Bonferroni==1, the p-value is multiplied by
%           epo.corrfac and cropped at 1.
%  .sgnlogp - contains the signed log10 p-value, if opt.Stats==1
%           if opt.Bonferroni==1, the p-value is multiplied by
%           epo.corrfac, cropped, and then logarithmized
%  .sigmask - binary array indicating significance at alpha level
%             opt.Alphalevel, if opt.Stats==1 and opt.Alphalevel > 0
%  .corrfac - Bonferroni correction factor (number of simultaneous tests), 
%             if opt.Bonferroni==1
%  .crit    - 'significance' threshold of t statistics with respect to 
%             level alpha
%
% Benjamin Blankertz
% 09-2012 stefan.haufe@tu-berlin.de
% 10-2015 Daniel Miklody

props= {  'Policy'   'mean' '!CHAR(mean nanmean median)';
          'Classes' 'ALL'   '!CHAR';
          'Std'      0      '!BOOL';
          'Stats'      0    '!BOOL';
          'Bonferroni' 0    '!BOOL';
          'Alphalevel' []   'DOUBLE'};

if nargin==0,
  out = props; return
end

misc_checkType(epo, 'STRUCT(x clab y)'); 
if nargin==2&&(iscellstr(varargin{1})||ischar(varargin{1}))
  opt.Classes = varargin{:};
else
  opt= opt_proplistToStruct(varargin{:});
end
[opt, isdefault]= opt_setDefaults(opt, props);
opt_checkProplist(opt, props);        
epo = misc_history(epo);

%% delegate a special case:
if isfield(epo, 'yUnit') && isequal(epo.yUnit, 'dB'),
  out= proc_dBAverage(epo, varargin{:});
  return;
end

%%		  
classes = opt.Classes;

if ~isfield(epo, 'y'),
  warning('no classes label found: calculating average across all epochs');
  nEpochs= size(epo.x, ndims(epo.x));
  epo.y= ones(1, nEpochs);
  epo.className= {'all'};
end

if isequal(opt.Classes, 'ALL'),
  classes= epo.className;
end
if ischar(classes), classes= {classes}; end
if ~iscell(classes),
  error('classes must be given cell array (or string)');
end
nClasses= length(classes);

if max(sum(epo.y,2))==1,
  warning('only one epoch per class - nothing to average');
  out= proc_selectClasses(epo, classes);
  out.N= ones(1, nClasses);
  return;
end

out= epo;
%  clInd= find(ismember(epo.className, classes));
%% the command above would not keep the order of the classes in cell 'ev'
evInd= cell(1,nClasses);
for ic= 1:nClasses,
  clInd= find(ismember(epo.className, classes{ic},'legacy'));
  evInd{ic}= find(epo.y(clInd,:));
end

sz= size(epo.x);
out.x= zeros(prod(sz(1:end-1)), nClasses);
if opt.Std,
  out.std= zeros(prod(sz(1:end-1)), nClasses);
end
if opt.Stats,
  out.se = zeros(prod(sz(1:end-1)), nClasses);
  out.p = zeros(prod(sz(1:end-1)), nClasses);
  out.tstat = zeros(prod(sz(1:end-1)), nClasses);
  out.sgnlogp = zeros(prod(sz(1:end-1)), nClasses);
end
out.y= eye(nClasses);
out.className= classes;
out.N= zeros(1, nClasses);
epo.x= reshape(epo.x, [prod(sz(1:end-1)) sz(end)]);
for ic= 1:nClasses,
  switch(lower(opt.Policy)),  %% alt: feval(opt.Policy, ...)
   case 'mean',
    out.x(:,ic)= mean(epo.x(:,evInd{ic}), 2);
   case 'nanmean',
    out.x(:,ic)= nanmean(epo.x(:,evInd{ic}), 2);
   case 'median',
    warning('median computation will be handled by proc_percentiles in the future');
    out.x(:,ic)= median(epo.x(:,evInd{ic}), 2);
   otherwise,
    error('unknown policy');
  end
  if opt.Std,
    if strcmpi(opt.Policy,'nanmean'),
      out.std(:,ic)= nanstd(epo.x(:,evInd{ic}), 0, 2);
    else
      out.std(:,ic)= std(epo.x(:,evInd{ic}), 0, 2);
    end
  end
  out.N(ic)= length(evInd{ic});
  if opt.Stats,
    if strcmpi(opt.Policy,'nanmean'),
      [H out.p(:, ic) ci stats] = ttest(epo.x(:,evInd{ic}), [], [], [], 2);
      out.se(:,ic)= stats.sd/sqrt(out.N(ic));
    else
      [H out.p(:, ic) ci stats] = ttest(epo.x(:,evInd{ic}), [], [], [], 2);
      out.se(:,ic)= stats.sd/sqrt(out.N(ic));
    end
    out.tstat(:, ic) = stats.tstat;
    out.df(ic) = stats.df(1);
    if ~isempty(opt.Alphalevel)
      out.crit(ic) = stat_calcTCrit(opt.Alphalevel, stats.df(1));
    end
  end
end

out.x= reshape(out.x, [sz(1:end-1) nClasses]);
if opt.Std,
  out.std= reshape(out.std, [sz(1:end-1) nClasses]);
end

if opt.Stats,
  out.tstat= reshape(out.tstat, [sz(1:end-1) nClasses]);
  out.se = reshape(out.se, [sz(1:end-1) nClasses]);
  out.p = reshape(out.p, [sz(1:end-1) nClasses]);
  if opt.Bonferroni
    out.corrfac = prod(sz(1:end-1));
    out.p = min(out.p*out.corrfac, 1);
  end  
  out.sgnlogp = -log10(out.p).*sign(out.x);
  if ~isempty(opt.Alphalevel)
    out.alphalevel = opt.Alphalevel;
    out.sigmask = out.p < opt.Alphalevel;
  end
end

out.indexedByEpochs = {}; 

