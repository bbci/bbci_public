function out = apply_logisticRegression(C, X, varargin)
% APPLY_LOGISTICREGRESSION - Apply existing logistic regresion classifier
%
%Synopsis:
%   C = apply_logisticRegression(C, X)
%
%Arguments:
%   X: DOUBLE [NxM] - Data matrix, with N features and M samples. 
%   C: STRUCT           - a logistic regression classifier structure.  Must include the
%                           field 'b'.
%   OPT: PROPLIST       - Structure or property/value list of optional
%                           properties. Options are also passed to clsutil_shrinkage.
%     'OriginalOutput'  - BOOL (default 0): If true, the orginal logistic regression output is returned (range [0 1])
%Returns:
%   out: FLOAT[]        - an array containing the classifier score for each 
%                           sample, in range [-1 1] (or alternatively [0 1])
%Description:
%   APPLY_LOGISTICREGRESSION applies a logistic regresion classifier given data and a
%   trained LR classifier.
%
%
%Examples:
%   apply_logisticRegression(C, X))
%   
%See also:
%   TRAIN_LOGISTICREGRESSION


props= {'OriginalOutput'      0                             'BOOL'
       };


opt= opt_proplistToStruct(varargin{:});
[opt, isdefault]= opt_setDefaults(opt, props);
opt_checkProplist(opt, props);

misc_checkType(X, 'DOUBLE');
misc_checkType(C, 'STRUCT(b)');

pihat = mnrval(C.b, X');

pihat = pihat';
out = pihat(1,:);
if ~opt.OriginalOutput
  out = 2*(out - 0.5);
end
