function proc= xvalutil_procSetDefault(proc)
% XVALUTIL_PROCSETDEFAULTS - Function used in crossvalidation

% 2014-02 Benjamin Blankertz


if isempty(proc),
  return;
end

if ~isfield(proc, 'train'),
  proc.train= {};
end

if ~isfield(proc, 'apply'),
  proc.apply= {};
end

proc.train= setDefaultProc(proc.train);
proc.apply= setDefaultProc(proc.apply);

return


function proc= setDefaultProc(proc)

for k= 1:length(proc),
  if ~iscell(proc{k}),
    proc{k}= {proc{k}};
  end
end
