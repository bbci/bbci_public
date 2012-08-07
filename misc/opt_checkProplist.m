function opt_checkProplist(opt, props, varargin)
%OPT_CHECKPROPLIST - Check a property/value struct according to specifications
%
%Synopsis:
%  opt_checkProplist(OPT, PROPSPEC, <PROPSPEC2, ...>)
%
%Arguments:
%  OPT:      STRUCT of optional properties
%  PROPSPEC: PROPSPECLIST - Property specification list, i.e., CELL of size
%      [N 2] or [N 3], with the first column all being strings.
%
%Returns:
%  nothing (just throws errors)
%
%Description:
%  This function checks whether all fields of OPT occur in the list of
%  property names of PROPSPEC and throws an error otherwise.
%  If PROPSPEC contains a third column of (type definitions), the values
%  in OPT are checked to match them, see opt_checkTypes.
%
%See also opt_checkTypes.
%
%Examples:
%  props= {'LineWidth', 2, 'DOUBLE[1]'; 'Color', 'k', 'CHAR|DOUBLE[3]'}
%  opt= struct('Color','g', 'LineStyle','-');
%  % This should throw an error:
%  opt_checkProplist(opt, props)
%  opt= struct('Color',[0.5 0.2 0.3 0.1]);
%  % This should also throw an error:
%  opt_checkProplist(opt, props)
%  opt= struct('Color',[0.1 0.6 0.3]);
%  % This is ok:
%  opt_checkProplist(opt, props)

% 06-2012 Benjamin Blankertz


props_all= cat(1, props, varargin{:});
fn= fieldnames(opt);
unknown_fields= setdiff(fieldnames(opt), props_all(:,1));
if ~isempty(unknown_fields),
  error('unexpected properties: %s.', vec2str(unknown_fields));
end

opt_checkTypes(opt, props);
