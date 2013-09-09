function yesorno= prochasfreevar(proc)
%yesorno= prochasfreevar(proc)
%
% Checks whether the transform proc has free variable without
% a unique assignment (or is a cell which means that the selection
% of the proc has not been made).
%
% SEE proc_applyProc, select_proc

yesorno= 0;
if iscell(proc),
  yesorno= 1;
elseif isstruct(proc) & isfield(proc, 'param'),
  nVals= cellfun(@length, {proc.param.value});
  if any(nVals>1) & ~isfield(proc, 'pvi'),
    yesorno= 1;
  end
end
