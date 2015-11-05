function fv_out= procutil_multiclassDiff(fv, diff_fnc, varargin)
%PROCUTIL_MULTICLASSDIFF - Wrapper function for multi-class differences
%
%Description: This function is a wrapper function that is used within
%  other functions that calculate a sort of difference between two
%  classes. PROCUTIL_MULTICLASSDIFF is used to apply those calling
%  functions to binary pairs of (combinations of) classes.
%
%Synopsis:
% FV_OUT= procutil_multiclassDiff(FV, FCN, <POLICY>)
% FV_OUT= procutil_multiclassDiff(FV, FCN, <OPT>)
%
%Arguments:
% FV: Feature vector structure
% FCN: Function which is called for pairwise differences
%      (this is typically the calling function).
%      The function can either be a string (then the function is called
%      without additional arguments), or a cell {FCN_NAME, FCN_PARAMS}
%      
% POLICY: Policy of doing the pairwise difference:
%      'pairwise' (default), 'each-against-last', 'each-against-rest',
%       OR a [nPairs x 2] sized matrix that explicitly specifies the pairs.
% OPT: Struct or property-value-list of optional properties. So far only
%   .policy: See above, argument POLICY.
%
%Returns:
% FV_OUT: Feature vector structure of roc values.
%
%See also:
% proc_rocAreaValues, proc_rValues, proc_rSquaredSigned, proc_tValues

% 10-2010 Benjamin Blankertz
% 07-2012 Johannes Hoehne - Updated documentation and parameter naming


props= {'policy'  'pairwise'  'DOUBLE[- 2]|CHAR(pairwise each-against-last each-against-rest)'};

if nargin==0,
  fv_out= props; return
end
fv = misc_history(fv);

if length(varargin)==1 && ~isstruct(varargin{1}) && ~isempty(varargin{1}),
  opt= struct('policy', varargin{1});
else
  opt= opt_proplistToStruct(varargin{:});
end
[opt, isdefault]= opt_setDefaults(opt, props, 1);


[fcn, params]= misc_getFuncParam(diff_fnc);

if ischar(opt.policy),
  switch(opt.policy),
   case 'pairwise'
    opt.policy= nchoosek(1:size(fv.y,1), 2);
   case 'each-against-last',
    ni= size(fv.y,1)-1;
    opt.policy= [[1:ni]' (ni+1)*ones(ni,1)];
  end
end

fv_out= [];
if isnumeric(opt.policy),
  for ic= 1:size(opt.policy,1),
    ep= proc_selectClasses(fv, opt.policy(ic,:), 'RemoveVoidClasses',0);
    fv_tmp= fcn(ep, params{:});
    fv_out= proc_appendEpochs(fv_out, fv_tmp);
  end
  return;
else
  switch(opt.policy),
   case 'each-against-rest',
    ni= size(fv.y,1);
    combs= zeros(ni,ni-1);
    for ic= 1:ni,
      combs(ic,:)= [1:ic-1, ic+1:ni];
    end
    for ic= 1:ni,
      ep= proc_combineClasses(fv, combs(ic,:));
      fv_tmp= feval(fcn, ep, params{:});
      fv_out = proc_appendEpochs(fv_out, fv_tmp);
    end
    return; 
   otherwise,
    error('unknown multiclass policy');
  end
end
