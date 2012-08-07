function fv_rval= proc_r_values(fv, varargin)
%PROC_R_VALUES - Computes the r-value for each feature
%
%Synopsis:
% FV_RVAL= proc_r_values(FVL, 'Property',Value, ...)
%
%Arguments:
% FV - data structure of feature vectors
%
%Returns:
% FV_RVAL - data structute of r values (one sample only)
%
%Properties:
% 'tolerateNans': observations with NaN value are skipped
%    (nanmean/nanstd are used instead of mean/std). Deafult: 0
% 'valueForConst': constant feauture dimensions are assigned this
%    value. Default: NaN.
% 'multiclassPolicy': possible options: 'pairwise' (default), 
%    'all-against-last', 'each-against-rest', or provide specified
%    pairs as an [nPairs x 2] sized matrix. ('specified_pairs' is obsolete)
% 
%Description:
% This function calculates the bi-serial correlation coefficient in
% each feature dimension. The output value for dimensions that are
% constant across all samples are set to NaN (by default, see
% property 'valueForConst').
%
%Examples:
%  [cnt, mrk]= eegfile_readBV(some_file);   %load EEG-data in BV-format
%  mrk= mrk_defineClasses(mrk, {1, 2; 'target','nontarget'}); 
%  epo= proc_segmentation(cnt, mrk, [-200 800], 'CLab', {'Fz','Cz','Pz'});
%  epo_r = proc_r_values(epo);
%
%See also:  proc_t_scaled, proc_r_square, proc_wr_multiclass_diff


% Benjamin Blankertz

props= { 'tolerateNans',       0,          'BOOL|DOUBLE'
         'valueForConst',     NaN,        'DOUBLE'
         'multiclassPolicy',   'pairwise', 'CHAR'  };

if nargin==0,
  fv_rval= props; return
end

misc_checkType('fv', 'STRUCT(x y)');

opt= opt_proplistToStruct(varargin{:});
[opt, isdefault]= opt_setDefaults(opt, props);
opt_checkProplist(opt, props);


if size(fv.y,1)>2,
  fv_rval= proc_wr_multiclass_diff(fv, {'r_values',opt}, ...
                                   opt.multiclassPolicy);
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
if opt.tolerateNans,
  stdi= @nanstd;
  meani= @nanmean;
  iV = reshape(sum(~isnan(fv.x), 2), [sz(1:end-1) 1])-3;
else
  stdi= @std;
  meani= @mean;
  iV = sz(end)*ones(sz(1:end-1))-3;
end
div= stdi(fv.x,0,2);
iConst= find(div==0);
div(iConst)= 1;
rval= ( (meani(fv.x(:,c1),2)-meani(fv.x(:,c2),2)) * sqrt(lp*lq) ) ./ ...
        ( div*(lp+lq) );
rval(iConst)= opt.valueForConst;
rval= reshape(rval, [sz(1:end-1) 1]);
iV= reshape(iV, [sz(1:end-1) 1]);

fv_rval= fv;
fv_rval.x= rval;
fv_rval.V= 1./iV;
fv_rval.z = atanh(fv_rval.x).*sqrt(iV);
fv_rval.p = reshape(2*normal_cdf(-abs(fv_rval.z(:)), zeros(size(fv_rval.z(:))), ones(size(fv_rval.z(:)))), size(fv_rval.z));
if exist('normcdf','file'),
  fv_rval.sgn_log10_p = reshape(((log(2)+normcdfln(-abs(fv_rval.z(:))))./log(10)), size(fv_rval.z)).*-sign(fv_rval.z);
end
if isfield(fv, 'className'),
  fv_rval.className= {sprintf('r( %s , %s )', fv.className{1:2})};
end
fv_rval.y= 1;
fv_rval.yUnit= 'r';
