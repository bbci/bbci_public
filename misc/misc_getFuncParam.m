function [func, params]= misc_getFuncParam(proc)
% misc_getFuncParam - Split processing into function name and parameters
%
% Synopsis:
%   [FUNC,PARAMS]= misc_getFuncParam(PROC)
%   
% Arguments:
%   PROC: String, function handle or cell array. Allowed cases:
%         'funcName' (name of the function to call, no params)
%         {'funcName', 'Param1', 'Param2', ...}
%           (name of the function to call, list of params)
%         {{'funcName', 'Param1', 'Param2', ...}}
%           (name of the function to call, list of params)
%   
% Returns:
%   FUNC:   [HANDLE]	Handle to the actual function to call
%   PARAMS: [CELL]    Parameters to be passed to the function given in 'FUNC'
%   
% Description:
%   The toolbox uses a standardized format of passing function name and
%   parameters. This routine tests the various allowed cases and returns
%   actual function name and parameters.
%   
% Examples:
%   [f,p] = getFuncParam(@callme)
%     returns f=@callme, p={}
%   [f,p] = getFuncParam({@callme, 'withParams'})
%     returns f=@callme, p={'withParams'}
%   [f,p] = getFuncParam({{@callme, 'with', 'Params'}})
%     returns f=@callme, p={'with', 'Params'}

% Benjamin Blankertz


error(nargchk(1, 1, nargin));
misc_checkType(proc, 'CHAR|FUNC|CELL');

if iscell(proc),
  func= proc{1};
  if iscell(func) && length(proc)==1,
    params= func(2:end);
    func= func{1};
  else
    params= proc(2:end);
  end
else
  func= proc;
  params={};
end

if ischar(func)
  func= str2func(func);
end
