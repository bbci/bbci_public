function [fv, opt]= proc_subtractMean(fv, varargin)
% PROC_SUBTRACTMEAN - Subtract mean or median from data, given in fv.
%
%Synopsis:
% [fv, opt]= proc_normalize(fv, opt)
%
%Arguments:
%     fv    - struct of feature vectors
%     opt  struct and/or property/value list of properties
%      .Policy - one of 'mean' (default), 'median', 'nanmean', 'nanmedian'
%      .Dim    - dimension along which the mean should be computed.
%                1 computes along the first dimension,
%                2 computes along the second dimension (default).
%      .Bias   - vector which is subtracted from fv. If this option is
%                given, the 'Policy' option is ignored. 
%                Typically the bias vector is computed in a first call to
%                proc_subtractMean. Thus, this field can be used to 
%                apply the shift calculated from one data set (e.g. 
%                training data) to another data set (e.g. test data)
%
%      fv   - struct of shifted feature vectors
%      opt  - a copy of the input options, with a new field .Bias that
%             contains the mean/median vector that has been
%             subtracted from the data.
%
% See also: nanmean

% bb 09/03, ida.first.fhg.de
% Anton Schwaighofer, Feb 2005
% Sven Daehne, Feb 2016, ported to git toolbox

fv = misc_history(fv);

props= { 'Policy'  'mean'    '!CHAR(mean median nanmean nanmedian)'
         'Dim'      2       'INT'
         };

if nargin==0,
  fv = props; return
end

misc_checkType(fv, 'STRUCT(x)');

% this allows the function to be called like 
% "proc_subtractMean(fv, 'mean')", i.e. without explictly stating 'Policy'
if length(varargin)==1 && ischar(varargin{1}),
  opt= struct('Policy', varargin{1});
else
  opt= opt_proplistToStruct(varargin{:});
end

opt = opt_setDefaults(opt, props);
opt_checkProplist(opt, props);


sz= size(fv.x);

if isfield(opt, 'Bias'),
  bsz= sz;
  bsz(opt.Dim)= 1;
  if ~isequal(size(opt.Bias), bsz),
    error('size of opt.Bias does not match fv');
  end
else
  switch(opt.Policy),
   case 'mean',
    opt.Bias= mean(fv.x, opt.Dim);
   case 'median',
    opt.Bias= median(fv.x, opt.Dim);
   case 'nanmean',
    opt.Bias= nanmean(fv.x, opt.Dim);
   case 'nanmedian',
    opt.Bias= nanmedian(fv.x, opt.Dim);
  end
end

rep_sz= ones(1, max(length(sz), opt.Dim));
rep_sz(opt.Dim)= sz(opt.Dim);

fv.x= fv.x - repmat(opt.Bias, rep_sz);
