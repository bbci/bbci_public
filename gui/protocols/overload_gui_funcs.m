function varargout = overload_gui_functions(fnc, paradigm, handles, varargin)

% check if the overloader file exposes this function
%  if not, proceed with default
%  if so, use the overloaded file
opt = opt_proplistToStruct(varargin{:});

paradigm = str2func(strcat('funcs_', paradigm));
default_func = @funcs_default;
if ismember(fnc, paradigm()),
    nec_param = paradigm(fnc, handles, 'variables');
    if ~isempty(nec_param{2}) & any(~ismember(nec_param{2}, fieldnames(opt))),
        id = find(~ismember(nec_param{2}, fieldnames(opt)));
        warning(sprintf('Missing parameter: %s\n', nec_param{2}{id}));
    end
    outs = paradigm(fnc, handles, opt);
    if outs{1}, % only works if ALL other outputs are structs
        outs = default_func(fnc, handles, outs{2:end}, opt);
    end
    varargout = outs(2:nargout+1);
elseif ismember(fnc, default_func()), 
    outs = default_func(fnc, handles, opt);
    varargout = outs(2:nargout+1);
else
    error('Unknown function. Please specify');
end