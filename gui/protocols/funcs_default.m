function cell_out = funcs_default(fnc, handles, varargin),

%%% The required behavior of any protocol file for when it's called with no
%%% argument is that it exposes the functions that it implements.
%%% When a subfunction is added, make it visible by adding it's name here.
if nargin == 0,
    cell_out = {'online_settings', ...
        'calibration_settings', ...
        'experiment_settings'};
    return;
end

%%% Start of part that should be left untouched.
fh = str2func(fnc);
[cell_out{1:nargout(fh)}] = fh(varargin{:});
if ~islogical(cell_out{1}),
    error('first output parameter of each subfunction must be bool');
end
%%% End of part that should be left untouched.

end

%%% Here you can add your own functions. They can overwrite those in
%%% default (fill_defaults is false), or extend them (fill_defaults is
%%% true). Any function added will only be visible if it's name is added
%%% above. 
function [fill_defaults, bbci] = online_settings(varargin),
    if isstruct(varargin{1}),
        bbci = bbci_apply_setDefaults(varargin{1});
    else
        bbci = bbci_apply_setDefaults;
    end
    fill_defaults = false;   
end

function [fill_defaults, bbci] = calibration_settings(varargin),
    if isstruct(varargin{1}),
        bbci = bbci_calibrate_setDefaults(varargin{1});
    else
        bbci = bbci_calibrate_setDefaults;
    end
    fill_defaults = false;
end

function [fill_defaults, experiments] = experiment_settings(varargin),
    experiments.names = {'No default experiments'};
    fill_defaults = false;
end