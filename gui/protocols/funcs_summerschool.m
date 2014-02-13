function cell_out = funcs_summerschool(fnc, handles, varargin),

%%% The required behavior of any protocol file for when it's called with no
%%% argument is that it exposes the functions that it implements.
%%% When a subfunction is added, make it visible by adding it's name here.
if nargin == 0,
    cell_out = {'online_settings', ...
        'calibration_settings', ...
        'experiment_settings', ...
        'run_experiments'};
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
if strcmp(varargin{1}, 'variables'),
    fill_defaults = false;
    bbci = {};
    return
elseif ~isempty(varargin{1}),
    bbci = varargin{1};
end
bbci.source.acquire_fcn = @bbci_acquire_offline;
bbci.source.acquire_param = {struct('fs', 100)};
bbci.log.output = 'screen&file';
bbci.log.classifier = 1;
bbci.control.fcn = @bbci_control_ERP_Speller_binary;
% bbci.feedback.receiver = 'tobi_c';
% bbci.feedback.host = '127.0.0.1';
% bbci.feedback.port = 12345;
bbci.feature.ival = varargin{1}.calibrate.settings.disp_ival;
bbci.quit_condition.marker = 254;
bbci.adaptation.active= 0;
bbci.adaptation.fcn= @bbci_adaptation_pcov_ERP;
bbci.adaptation.load_classifier= 0; % no need to load classifier
opt_adapt = [];
opt_adapt.alpha = 0.05;
opt_adapt.mrk_end_of_segment = 2;
opt_adapt.min_n_data_points = 100;
opt_adapt.mrk_stimuli = [20:32]; 
bbci.adaptation.param= {opt_adapt};
fill_defaults = true;
end

function [fill_defaults, bbci] = calibration_settings(varargin),
if ~isempty(varargin{1}) && strcmp(varargin{1}, 'variables'),
    fill_defaults = false;
    bbci = {};
    return
elseif ~isempty(varargin{1}),
    bbci = varargin{1};
end

global BTB;

% % % get preset intervals
% % ivals = [80,350; 360, 800];
% % deltas = [20, 60];
% % opt.cfy_ival = [];
% % for k=1:size(ivals,1)
% %     t_lims = ivals(k,:);
% %     dt = deltas(k);
% %     sampling_points = t_lims(1):dt:t_lims(2);
% %     tmp_ivals = round([sampling_points' - dt/2, sampling_points' + dt/2]);
% %     opt.cfy_ival = [opt.cfy_ival; tmp_ivals];
% % end

bbci.calibrate.folder = BTB.Tp.Dir;
bbci.calibrate.file =  'SETBYGUI';
bbci.calibrate.read_fcn = @file_readBV;
bbci.calibrate.read_param = {'fs', 100};
bbci.calibrate.marker_fcn = @mrk_defineClasses;
bbci.calibrate.marker_param = {{[30:49], [10:29]; 'Target', 'Non-target'}};
bbci.calibrate.save.file = 'bbci_classifier';
bbci.calibrate.save.overwrite = 0;
bbci.calibrate.save.figures = 0;
bbci.calibrate.fcn = @bbci_calibrate_ERP_Speller;
bbci.calibrate.settings = struct(...
    'disp_ival', [-150 1000], ...
    'ref_ival', [-150 0], ... % be aware that if this is turned off, a bandpass filter should be set
    'band', [40], ... 
    'cfy_clab', {{'not','E*','Fp*','AF*','A*'}}, ...
    'cfy_ival', 'auto', ...
    'control_per_stimulus', 1, ...
    'model', {{@train_RLDAshrink, 'StoreMeans', 1, 'StoreCov', 1}}, ...
    'nSequences', 10, ...
    'nClasses', 6, ...
    'cue_markers', [10:39], ...
    'create_figs', 0);
%bbci.calibrate.early_stopping_fnc = @bbci_train_rankdiff;
%bbci.calibrate.early_stopping_param = {'indices', {[1:6], [7:12];'rows', 'columns'}, ...
%    'nClasses', 12, ...
%    'nIters', 12};
fill_defaults = false;
end

function [fill_defaults, experiments] = experiment_settings(varargin),
%%% This function is potentially very verbose, as it defines all the
%%% parameters for the different experiments.
if strcmp(varargin{1}, 'variables'),
    fill_defaults = false;
    experiments = {};
    return
end

global BTB
BTB.Tp.Geometry = [1280, 0, 1024, 768];
fill_defaults = false;

% filenames to use
experiments.classifier_name = {'bbci_classifier'};
experiments.allowed_files = {'calibration_Hexo', 'calibration_Center', 'calibration_Cake'};%, ...
%    'online_copy_Hexo', 'online_copy_Center', 'online_copy_Cake'};

% define the types of experiments and some GUI settings for them
experiments.experiment_names = {'Online simulation (Hexo)', 'Online simulation (Center)', 'Online simulation (Cake)'};
experiments.requires_online = [1 1 1];
experiments.requires_adaptation = [0 0 0];
experiments.requires_stopping = [0 0 0];
experiments.simulated_run = [1 1 1];
experiments.editable_params = {{}, {}, {}};

% set the experiment specific parameters
experiments.parameters.(genvarname('Online simulation (Hexo)')) = struct(...
    'filename', 'calibration_HexoSpellerVE_VPibj' ...
    );
experiments.parameters.(genvarname('Online simulation (Center)')) = ...
    opt_proplistToStruct(experiments.parameters.(genvarname('Online simulation (Hexo)')), ...
    'filename', 'online_copy_CenterSpellerVE_VPibj' ...
    );
experiments.parameters.(genvarname('Offline simulation (Cake)')) = ...
    opt_proplistToStruct(experiments.parameters.(genvarname('Online simulation (Hexo)')), ...
    'filename', 'online_copy_CakeSpellerVE_VPibj' ...
    );   
end

function [fill_defaults, output] = run_experiments(varargin),
%%% This function is potentially very verbose, as it defines all the
%%% parameters for the different experiments.
if strcmp(varargin{1}, 'variables'),
    fill_defaults = false;
    output = {};
    return
end

global BTB
output = [];
fill_defaults = false;

% parse input parameters
experiment = varargin{1}.experiment;
ES = varargin{1}.parameters;
bbci = varargin{1}.bbci;
ES.use_signal_server = strcmp(func2str(bbci.source.acquire_fcn), 'bbci_acquire_sigserv');

% run the actual experiments
[cnt mrko] = file_readBV([BTB.Tp.Dir ES.filename], 'fs', bbci.source.acquire_param{1}.fs);
mrk = bbci.calibrate.marker_fcn(mrko, bbci.calibrate.marker_param{:});
bbci.source.acquire_param = {cnt, mrk}; 
dat = bbci_apply(bbci)

end
