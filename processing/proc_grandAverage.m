function ga= proc_grandAverage(varargin)
% PROC_GRANDAVERAGE -  calculates the grand average ERPs or ERD/ERS,
% r, r^2, sgn r^2, or auc scores from given set of data.
%
%Usage:
%ga= proc_grandAverage(erps)
%ga= proc_grandAverage(erps, <OPT>)
%ga= proc_grandAverage(erp1, <erp2, ..., erpN>, <Prop1>, <Val1>, ...)
%
% IN   erps  -  cell array of erp structures
%      erpn  -  erp structure
%
% <OPT> - struct or property/value list of optional fields/properties:
%   Average   - If 'Nweighted', each ERP is weighted for the number of
%               epochs (giving less weight to ERPs made from a small number
%               of epochs). This amounts to computing the arithmetic mean
%               across all epochs of all subjects.
%               If 'INVVARweighted', each individual quantity is weighted
%               by the inverse of its variance. For this, the standard error
%               must be provided in erp{:}.se. The inverse
%               variance weighting is optimal in the sense that the weighted
%               average has minimum variance.
%               Default 'arithmetic': this is the arithmetic mean of all
%               individual means, disregarding potentially different
%               variances and numbers of trials 
%   MustBeEqual - fields in the erp structs that must be equal across
%                 different structs, otherwise an error is issued
%                 (default {'fs','y','className'})
%   ShouldBeEqual - fields in the erp structs that should be equal across
%                   different structs, gives a warning otherwise
%                   (default {'yUnit'})
%   Stats       If true, additional statistics are calculated, including the
%               standard error of the GA, the p-value for the null 
%               Hypothesis, and the "signed log p-value".
%               If the stats flag is set when calling, e.g., proc_average 
%               on the subject level, then the variance of the subject-level
%               statistics is taken into account in order to boost
%               statistical power. If this is not the case, then a 
%               two-sided one-sample t-test for zero mean of the subject-level
%               average statistics is conducted. The variance of the 
%               subject-level statistics is then not taken into account,
%               which decreases statistical power of the test.
%  
%               Note that for general data, the null-Hypothesis states that
%               the GA has zero mean. For 'r', 'r^2', 'sgn r^2' values
%               that implies that there is zero linear correlation between 
%               feature and class label. For 'auc' scores, this
%               correlation is tested nonparametrically.
%
%               Since 'r', 'r^2', 'sgn r^2' scores are not
%               Gaussian distributed quantities, appropriate
%               transformations are applied before grand-averaging, which
%               make these quantities approximately Gaussian-distributed
%               with standard error erps{}.se . After averaging, the
%               inverse transformation is applied to obtain grand-average 
%               'r', 'r^2' or 'sgn r^2' scores.  
%
% 'Bonferroni' - if true, Bonferroni corrected is used to adjust p-values
%                and their logarithms
% 'Alphalevel' - if provided, a binary indicator of the significance to the
%                alpha level is returned for each feature in fv_rval.sigmask
%
%Output:
% ga: Grand average
%  .x    - grand average data
%  .se   - contains the standard error of the GA, if opt.Stats==1
%  .p     - contains the p value of the null hypothesis, if opt.Stats==1
%           If opt.Bonferroni==1, the p-value is multiplied by
%           epo.corrfac, and cropped to 1
%  .sgnlogp - contains the signed log10 p-value, if opt.Stats==1
%           if opt.Bonferroni==1, the p-value is multiplied by
%           epo.corrfac, cropped, and then logarithmized
%  .tstat   - Student t statistics, if opt.Stats==1, but no standard
%             errors on the subject level are given
%  .df      - degrees of freedom of the t distribution (one sample test)
%  .sigmask - binary array indicating significance at alpha level
%             opt.Alphalevel, if opt.Stats==1 and opt.Alphalevel > 0
%  .corrfac - Bonferroni correction factor (number of simultaneous tests), 
%             if opt.Bonferroni==1
%  .crit    - 'significance' threshold of t statistics with respect to 
%             level alpha
%
% 09-2012 stefan.haufe@tu-berlin.de

props = {   'Average'               'arithmetic'                '!CHAR(Nweighted INVVARweighted arithmetic)';
            'MustBeEqual'           {'fs','y','className'}      'CHAR|CELL{CHAR}';
            'ShouldBeEqual'         {'yUnit'}                   'CHAR|CELL{CHAR}';
            'Stats'                 0                           '!BOOL';
            'Bonferroni' 0    '!BOOL';
            'Alphalevel' []   'DOUBLE'};

if nargin==0,
  ga=props; return
end

%% Process input arguments
if iscell(varargin{1}),
  erps= varargin{1};
  opt= opt_proplistToStruct(varargin{2:end});
else
  iserp= cellfun(@isstruct,varargin);
  nerps= find(iserp,1,'last');
  erps= varargin(1:nerps);
  opt= opt_proplistToStruct(varargin{nerps+1:end});
end


[opt, ~]= opt_setDefaults(opt, props);
opt_checkProplist(opt, props);

misc_checkType(erps,'CELL{STRUCT}');

%% Get common electrode set
clab= erps{1}.clab;
for vp= 2:length(erps),
  clab= intersect(clab, erps{vp}.clab,'legacy');
end
if isempty(clab),
  error('intersection of channels is empty');
end
clab = erps{1}.clab(ismember(erps{1}.clab, clab)); %take channel-order of the first epo as reference!

%% Define ga data field
datadim = unique(cellfun(@util_getDataDimension,erps));
if numel(datadim) > 1
  error('Datasets have different dimensionalities');
end

if strcmp(opt.Average, 'INVVARweighted') && ~isfield(erps{1}, 'se')
   warning('Weighting with the inverse variance is not possible for this data. Performing arithmetic (unweighted) averaging instead.') 
   opt.Average = 'arithmetic';
end

if strcmp(opt.Average, 'Nweighted') && ~isfield(erps{1}, 'N')
   warning('Weighting with the number of trials is not possible for this data. Performing arithmetic (unweighted) averaging instead.') 
   opt.Average = 'arithmetic';
end

if opt.Stats && ~isfield(erps{1}, 'se')
   warning('No subject-level standard errors given for grand-average statistical analysis. Performing a simple t-test.') 
   opt.Stats = 0;
   simpleStats = 1;
else
   simpleStats = 0;
end

ga= rmfield(erps{1},intersect(fieldnames(erps{1}),{'x', 'std', 'tstat', 'crit', 'df'},'legacy'));
must_be_equal= intersect(opt.MustBeEqual, fieldnames(ga),'legacy');
should_be_equal= intersect(opt.ShouldBeEqual, fieldnames(ga),'legacy');

K = length(erps);
ci= util_chanind(erps{1}, clab);
C = length(ci);
if datadim==1
  T= size(erps{1}.x, 1);
  E= size(erps{1}.x, 3);
  F = 1;
else
  % Timefrequency data
  if ndims(erps{1}.x)==3  
    F= size(erps{1}.x, 1);
    T= size(erps{1}.x, 2);
    E = 1;
  elseif ndims(erps{1}.x)==4
    F= size(erps{1}.x, 1);
    T= size(erps{1}.x, 2);
    E= size(erps{1}.x, 4);
  end
end


for vp= 1:K,
  for jj= 1:length(must_be_equal),
    fld= must_be_equal{jj};
    if ~isequal(getfield(ga,fld), getfield(erps{vp},fld)),
      error('inconsistency in field %s.', fld);
    end
  end
  for jj= 1:length(should_be_equal),
    fld= should_be_equal{jj};
    if ~isequal(getfield(ga,fld), getfield(erps{vp},fld)),
      warning('inconsistency in field %s.', fld);
    end
  end
  ci= util_chanind(erps{vp}, clab);

  if datadim==1
    erps{vp}.x = reshape(erps{vp}.x(:,ci,:), [], E);
    if opt.Stats
      erps{vp}.se = reshape(erps{vp}.se(:,ci,:), [], E);
    end
  else
    if ndims(erps{1}.x)==3
      erps{vp}.x = reshape(erps{vp}.x(:,:,ci), [], E);
      if opt.Stats
        erps{vp}.se = reshape(erps{vp}.se(:,:,ci), [], E);
      end
    elseif ndims(erps{1}.x)==4
      erps{vp}.x = reshape(erps{vp}.x(:,:,ci,:), [], E);
      if opt.Stats
        erps{vp}.se = reshape(erps{vp}.se(:,:,ci,:), [], E);
      end
    end
  end

  %% Pre-transformation to make the data (more) zero-mean Gaussian for some known statistics
  if isfield(ga, 'yUnit') 
    switch ga.yUnit
      case 'dB'
        erps{vp}.x = 10.^(erps{vp}.x/10);
      case 'r',
        erps{vp}.x = atanh(erps{vp}.x);
      case 'r^2',
        erps{vp}.x = atanh(sqrt(erps{vp}.x));
      case 'sgn r^2',
        erps{vp}.x = atanh(sqrt(abs(erps{vp}.x)).*sign(erps{vp}.x));
    end
  end
  
end


ga.x = zeros([F*T*C E]);
if opt.Stats
  ga.se = zeros([F*T*C E]);
end
for cc= 1:E,  %% for each class
  sW= 0;
  swV = 0;
  tdata = zeros([F*T*C K]);
  for vp= 1:K,  %% average across subjects
    switch opt.Average
      case 'Nweighted',
        W = erps{vp}.N(cc);
      case 'INVVARweighted'
        W = 1./erps{vp}.se(:, cc).^2;
      otherwise % case 'arithmetic'
        W = 1;
    end
    sW= sW + W;
    ga.x(:, cc)= ga.x(:, cc) + W.*erps{vp}.x(:, cc); 
    if opt.Stats
      swV = swV + W.^2.*erps{vp}.se(:, cc).^2;
    else
      if simpleStats
        tdata(:, vp) = W.*erps{vp}.x(:, cc);
      end
    end
  end
  ga.x(:, cc)= ga.x(:, cc)./sW;
  if opt.Stats
    ga.se(:, cc) = sqrt(swV)./sW;
  else
    if simpleStats
      [~, ga.p(:, cc), ~, stats] = ttest(tdata, [], [], [], 2);
      ga.tstat(:, cc) = stats.tstat;
      ga.se(:,cc)= stats.sd/sqrt(K);
      ga.df = stats.df(1);
    end
  end
end

if datadim==1
  ga.x = reshape(ga.x, [T C E]);
else
  % Timefrequency data
  if ndims(erps{1}.x)==3   % only one class
    ga.x = reshape(ga.x, [F T C]);  
  elseif ndims(erps{1}.x)==4
    ga.x = reshape(ga.x, [F T C E]);
  end
end
  
if opt.Stats
  ga.p = reshape(2*stat_normal_cdf(-abs(ga.x(:)), zeros(size(ga.x(:))), ga.se(:)), size(ga.x));
end

if simpleStats
  ga.p = reshape(ga.p, size(ga.x));
  ga.tstat = reshape(ga.tstat, size(ga.x));
end

if opt.Stats || simpleStats
  if opt.Bonferroni
    ga.corrfac = F*T*C*E;
    ga.p = min(ga.p*ga.corrfac, 1);
    ga.sgnlogp = -reshape(min(((log(2)+normcdfln(-abs(ga.x(:)./ga.se(:))))./log(10)+abs(log10(ga.corrfac))), 0), size(ga.x)).*sign(ga.x);
  else
    ga.sgnlogp = -reshape(((log(2)+normcdfln(-abs(ga.x(:)./ga.se(:))))./log(10)), size(ga.x)).*sign(ga.x);
  end  

  if ~isempty(opt.Alphalevel)
    ga.alphalevel = opt.Alphalevel;
    ga.sigmask = ga.p < opt.Alphalevel;
    if simpleStats
      ga.crit = stat_calcTCrit(opt.Alphalevel, ga.df);
    end
  end
end

%% Post-transformation to bring the GA data back to the original unit
if isfield(ga, 'yUnit') 
  switch ga.yUnit
    case 'dB'
      ga.x= 10*log10(ga.x);
    case 'r',
      ga.x= tanh(ga.x);
    case 'r^2',
      ga.x= tanh(ga.x).^2;
    case 'sgn r^2',
      ga.x= tanh(ga.x).*abs(tanh(ga.x));
    case 'auc'
      ga.x = min(max(ga.x, -1), 1);
  end
end

ga.clab= clab;

ga.title= 'grand average';
ga.N= length(erps);
