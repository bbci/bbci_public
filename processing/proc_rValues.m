function fv_rval= proc_rValues(fv, varargin)
%PROC_RVALUES - Computes the r-value for each feature
%
%Synopsis:
% FV_RVAL= proc_rValues(FVL, 'Property',Value, ...)
%
%Arguments:
% FV - data structure of feature vectors
%
%Returns:
% FV_RVAL - data structure of r values 
%  .se    - contains the standard error of atanh(r), if opt.Stats==1
%  .p     - contains the p value of null hypothesis that there is zero
%           correlation between feature and class-label, if opt.Stats==1
%  .sgnlogp - contains the signed log10 p-value, if opt.Stats==1
%
%Properties:
% 'TolerateNans': observations with NaN value are skipped
%    (nanmean/nanstd are used instead of mean/std). Deafult: 0
% 'ValueForConst': constant feauture dimensions are assigned this
%    value. Default: NaN.
% 'MulticlassPolicy': possible options: 'pairwise' (default), 
%    'all-against-last', 'each-against-rest', or provide specified
%    pairs as an [nPairs x 2] sized matrix. ('specified_pairs' is obsolete)
% 'Stats' - if true, additional statistics are calculated, including the
%           standard error of atanh(r), the p-value for the null 
%           Hypothesis that the correlation is zero, 
%           and the "signed log p-value"
% 
%Description:
% This function calculates the bi-serial correlation coefficient in
% each feature dimension. The output value for dimensions that are
% constant across all samples are set to NaN (by default, see
% property 'valueForConst').
%
%Examples:
%  [cnt, mrk]= file_readBV(some_file);   %load EEG-data in BV-format
%  mrk= mrk_defineClasses(mrk, {1, 2; 'target','nontarget'}); 
%  epo= proc_segmentation(cnt, mrk, [-200 800], 'CLab', {'Fz','Cz','Pz'});
%  epo_r = proc_rValues(epo);
%
%See also:  proc_tTest, proc_rSquare, proc_rSquareSigned

% Benjamin Blankertz
% 09-2012 stefan.haufe@tu-berlin.de

props= { 'TolerateNans',      0,           'BOOL|DOUBLE'
         'ValueForConst',     NaN,         'DOUBLE'
         'MulticlassPolicy',  'pairwise',  'CHAR(pairwise all-against-last each-against-rest)|INT[- 2]'  
         'Stats',             0,           '!BOOL';
         'Bonferroni' 0    '!BOOL';
         'Alphalevel' []   'DOUBLE'};

if nargin==0,
  fv_rval= props; return
end

fv = misc_history(fv);
misc_checkType(fv, 'STRUCT(x y)');

opt= opt_proplistToStruct(varargin{:});
[opt, isdefault]= opt_setDefaults(opt, props);
opt_checkProplist(opt, props);


if size(fv.y,1)>2,
  fv_rval= procutil_multiclassDiff(fv, {'rValues',opt}, ...
                                   opt.MulticlassPolicy);
  return;
elseif size(fv.y,1)==1,
  bbci_warning('1 class only: calculating r-values against flat-line of same var', 'r_policy');
  fv2= fv;
  szx= size(fv.x);
  fv2.x= fv2.x - repmat(mean(fv2.x,3), [1 1 size(fv2.x,3)]);
  fv2.className= {'flat'};
  fv= proc_appendEpochs(fv, fv2);
end

sz= size(fv.x);
fv.x= reshape(fv.x, [prod(sz(1:end-1)), sz(end)]);
c1= find(fv.y(1,:));
c2= find(fv.y(2,:));
lp= length(c1);
lq= length(c2);
if opt.TolerateNans,
  stdi= @nanstd;
  meani= @nanmean;
  if opt.Stats
    iV = reshape(sum(~isnan(fv.x), 2), [sz(1:end-1) 1])-3;
  end
else
  stdi= @std;
  meani= @mean;
  if opt.Stats
    iV = sz(end)*ones(sz(1:end-1))-3;
  end
end
div= stdi(fv.x,0,2);
iConst= find(div==0);
div(iConst)= 1;
rval= ( (meani(fv.x(:,c1),2)-meani(fv.x(:,c2),2)) * sqrt(lp*lq) ) ./ ...
        ( div*(lp+lq) );
rval(iConst)= opt.ValueForConst;
rval= reshape(rval, [sz(1:end-1) 1]);

fv_rval= fv;
fv_rval.x= rval;

if opt.Stats
  iV= reshape(iV, [sz(1:end-1) 1]);
  fv_rval.se = 1./sqrt(iV);
  fv_rval.p = reshape(2*normal_cdf(-abs(atanh(fv_rval.x(:))), zeros(size(fv_rval.x(:))), fv_rval.se(:)), size(fv_rval.x));
  if opt.Bonferroni
    fv_rval.corrfac = prod(sz(1:end-1));
    fv_rval.p = min(fv_rval.p*fv_rval.corrfac, 1);
    fv_rval.sgnlogp = -reshape(((log(2)+normcdfln(-abs(atanh(fv_rval.x(:)).*sqrt(iV(:)))))./log(10))+abs(log10(fv_rval.corrfac)), size(fv_rval.x)).*sign(fv_rval.x);
  else
    fv_rval.sgnlogp = -reshape(((log(2)+normcdfln(-abs(atanh(fv_rval.x(:)).*sqrt(iV(:)))))./log(10)), size(fv_rval.x)).*sign(fv_rval.x);
  end  
  if isfield(opt, 'Alphalevel')
    fv_rval.alphalevel = opt.Alphalevel;
    fv_rval.sigmask = fv_rval.p < opt.Alphalevel;
  end
end

if isfield(fv, 'className'),
  fv_rval.className= {sprintf('r( %s , %s )', fv.className{1:2})};
end
fv_rval.y= 1;
fv_rval.yUnit= 'r';
