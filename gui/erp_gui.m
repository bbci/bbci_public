function varargout = erp_gui(varargin)
% P300_GUI M-file for p300_gui.fig
%      P300_GUI, by itself, creates a new P300_GUI or raises the existing
%      singleton*.
%
%      H = P300_GUI returns the handle to a new P300_GUI or the handle to
%      the existing singleton*.
%
%      P300_GUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in P300_GUI.M with the given input arguments.
%
%      P300_GUI('Property','Value',...) creates a new P300_GUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before p300_gui_OpeningFunction gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to p300_gui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help p300_gui

% Last Modified by GUIDE v2.5 21-Sep-2012 16:43:44

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @erp_gui_OpeningFcn, ...
    'gui_OutputFcn',  @erp_gui_OutputFcn, ...
    'gui_LayoutFcn',  [] , ...
    'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before p300_gui is made visible.
function erp_gui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to p300_gui (see VARARGIN)

% Choose default command line output for p300_gui
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes p300_gui wait for user response (see UIRESUME)
% uiwait(handles.figure1);
addpath(strcat(fileparts(mfilename('fullpath')), '/protocols/'));
addpath(strcat(fileparts(mfilename('fullpath')), '/auxillary/'));
manage_parameters('reset');
state.loaded = false; state.inited = false; state.trained = false;
state.pyff_started = false; state.sigserv_started = false; state.bv_started = false;
manage_parameters('set', 'state', state);



% --- Outputs from this function are returned to the command line.
function varargout = erp_gui_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

function message_box_Callback(hObject, eventdata, handles)
% hObject    handle to message_box (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of message_box as text
%        str2double(get(hObject,'String')) returns contents of message_box as a double


% --- Executes during object creation, after setting all properties.
function message_box_CreateFcn(hObject, eventdata, handles)
% hObject    handle to message_box (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in file_list_box.
function file_list_box_Callback(hObject, eventdata, handles)
% hObject    handle to file_list_box (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns file_list_box contents as cell array
%        contents{get(hObject,'Value')} returns selected item from file_list_box


% --- Executes during object creation, after setting all properties.
function file_list_box_CreateFcn(hObject, eventdata, handles)
% hObject    handle to file_list_box (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in load_data_button.
function load_data_button_Callback(hObject, eventdata, handles)
% hObject    handle to load_data_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if check_state(handles,1),
    try,
        GB = manage_parameters('get', 'global_bbci');
        set_button_state(handles, 'off', {''});
        add_to_message_box(handles, 'Loading data. Please wait.....');drawnow;
        bbci = manage_parameters('get', 'bbci');
        sel_files = get_selected_item(handles.file_list_box);
        bbci.calibrate.file = cellfun(@(X) strcat(GB.RawDir, X), ...
            sel_files, 'UniformOutput', false);
        bbci.calibrate.folder = []; 
        data = bbci_load(bbci);
        manage_parameters('set', 'data', data);
        set_button_state(handles, 'on', {''});
        manage_parameters('update', 'state.loaded', true);
        reset_channel_names(handles);      
        update_nr_chan_selected(handles);
        add_to_message_box(handles, 'Data loaded.');    
   catch
       error = lasterror;
       disp(error.message);
       set_button_state(handles, 'on', {''});
       add_to_message_box(handles, 'Something went wrong, so I didn''t load any data. I don''t deal well with interrupted trials, so don''t load those.');
    end
else
    add_to_message_box(handles, 'Please initialize first...');        
end            

% --- Executes on button press in init_button.
function init_button_Callback(hObject, eventdata, handles)
% hObject    handle to init_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if strcmp(get(handles.vp_code_box, 'string'), 'Enter usercode'),
    add_to_message_box(handles, 'Error: No valid usercode set.');
%elseif isempty(strmatch('VP', get(handles.vp_code_box, 'string'))) && ~isempty(get(handles.vp_code_box, 'string')),
%    add_to_message_box(handles, ...
%        'Error: Invalid BBCI.Tp.Code set. BBCI.Tp.Code should start with VP');
else
    global BBCI;
    if isempty(get(handles.vp_code_box, 'string')),
        %clear BBCI.Tp.Code;
        set(handles.vp_code_box, 'string', GB.Tp.Code);
    else
        BBCI.Tp.Code = get(handles.vp_code_box, 'string');
    end
    acq_makeDataFolder('multiple_folders', 0);
    
    % get all the parameters in buffer
    try
        state = manage_parameters('get', 'state');    
    catch
        state.pyff_started = false;
        state.bv_started = false;
        state.sigserv_started = false;
    end
    manage_parameters('reset');
    manage_parameters('set', 'global_bbci', BBCI); 
    GB = BBCI;
    [study, study_id] = get_selected_item(handles.study_box); 
    study = study{1};
    experiments = manage_parameters('set', 'experiment_settings', ...
        overload_gui_funcs('experiment_settings', study, handles));  
    BC = overload_gui_funcs('calibration_settings', study, handles); 
    bbci = manage_parameters('set', 'bbci', ...
       overload_gui_funcs('online_settings', study, handles, BC)); 
    set(handles.experiment_box, 'string', experiments.experiment_names);
    look_for_existing_files(handles, ...
        experiments.allowed_files, '.eeg', get(handles.individual_files_tick, 'value'), ...
        get(handles.today_only_tick, 'value'), handles.file_list_box);
    look_for_existing_files(handles, ...
        experiments.classifier_name, '.mat', 1, ...
        get(handles.today_only_classifier_tick, 'value'),handles.run_classifier_menu);
    state.inited = true; state.trained = false; state.loaded = false;state.vpcode = GB.Tp.Code; state.study = study;
    manage_parameters('set', 'state', state);
    handle_experiment_parameters(handles, 'init');
    manage_parameters('dump');
    %send_tobi_c_udp('init', '127.0.0.1', 12345);
%    send_xmlcmd_udp('init', '127.0.0.1', 12345);
%    if handles.amp_button_gtec, 
%        acquire_func = @acquire_sigserv;
%    else
%        acquire_func = @acquire_bv;
%    end
end

% --- Executes on button press in create_images_button.
function create_images_button_Callback(hObject, eventdata, handles)
% hObject    handle to create_images_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if check_state(handles,2),
%     try
        set_button_state(handles, 'off', {''});
        data = manage_parameters('get', 'data');
        bbci = manage_parameters('get', 'bbci');
        [sel_class class_id] = get_selected_item(handles.choose_classifier_popup);
        bbci.calibrate.settings.model = str2func(['@train_' sel_class{1}]);        
        bbci.calibrate.settings.reject_channels = get(handles.reject_channels_tick, 'value');
        bbci.calibrate.settings.create_figs = 1;
        try,bbci.calibrate = rmfield(bbci.calibrate, 'early_stopping_fnc');end
        bbci_calibrate(bbci, data);           
        figure(handles.figure1);
        set_button_state(handles, 'on', {''});
%     catch
%         error = lasterror;
%         disp(error.message);
%         set_button_state(handles, 'on', {''});
%         add_to_message_box(handles, 'Visualization didn''t work. Is it implemented properly?');
%     end
else
    add_to_message_box(handles, 'Please initialize and load data first...');
end

% --- Executes on button press in close_images_button.
function close_images_button_Callback(hObject, eventdata, handles)
% hObject    handle to close_images_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
close_images_but_not_gui();

function vp_code_box_Callback(hObject, eventdata, handles)
% hObject    handle to vp_code_box (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of vp_code_box as text
%        str2double(get(hObject,'String')) returns contents of vp_code_box as a double

% --- Executes during object creation, after setting all properties.
function vp_code_box_CreateFcn(hObject, eventdata, handles)
% hObject    handle to vp_code_box (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
global BBCI
if ~isempty(BBCI.Tp.Code),
    set(hObject, 'string', BBCI.Tp.Code);
end

% --- Executes on selection change in study_box.
function study_box_Callback(hObject, eventdata, handles)
% hObject    handle to study_box (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns study_box contents as cell array
%        contents{get(hObject,'Value')} returns selected item from study_box


% --- Executes during object creation, after setting all properties.
function study_box_CreateFcn(hObject, eventdata, handles)
% hObject    handle to study_box (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
p = mfilename('fullpath');
dlist = dir([fileparts(p) '/protocols/']);
str = {};
matchStr = 'funcs_';
for i = 1:length(dlist),
    if ~dlist(i).isdir && ~isempty(strmatch(matchStr, dlist(i).name)) && ~strcmp(dlist(i).name, 'funcs_default.m'),
        str{length(str)+1} = dlist(i).name(length(matchStr)+1:end-2);
    end
end
set(hObject, 'string', sort(str));
photo_id = strmatch('photobrowser',sort(str));
set(hObject, 'value', photo_id);

% --- Executes on button press in relist_files_button.
function relist_files_button_Callback(hObject, eventdata, handles)
% hObject    handle to relist_files_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
experiments = manage_parameters('get', 'experiment_settings');
look_for_existing_files(handles, ...
        experiments.allowed_files, '.eeg', get(handles.individual_files_tick, 'value'), ...
        get(handles.today_only_tick, 'value'), handles.file_list_box);


% --- Executes on button press in individual_files_tick.
function individual_files_tick_Callback(hObject, eventdata, handles)
% hObject    handle to individual_files_tick (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of individual_files_tick
experiments = manage_parameters('get', 'experiment_settings');
look_for_existing_files(handles, ...
        experiments.allowed_files, '.eeg', get(handles.individual_files_tick, 'value'), ...
        get(handles.today_only_tick, 'value'),handles.file_list_box);


% --- Executes on button press in today_only_tick.
function today_only_tick_Callback(hObject, eventdata, handles)
% hObject    handle to today_only_tick (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of today_only_tick
experiments = manage_parameters('get', 'experiment_settings');
look_for_existing_files(handles, ...
        experiments.allowed_files, '.eeg', get(handles.individual_files_tick, 'value'), ...
        get(handles.today_only_tick, 'value'),handles.file_list_box);
    
% --- Executes on button press in reject_channels_tick.
function reject_channels_tick_Callback(hObject, eventdata, handles)
% hObject    handle to reject_channels_tick (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of reject_channels_tick

% --- Executes on button press in train_classifier_button.
function train_classifier_button_Callback(hObject, eventdata, handles, clab, stopping)
% hObject    handle to train_classifier_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
restore_data = 1;
if check_state(handles,2),
    [sel_class class_id] = get_selected_item(handles.choose_classifier_popup);
    if class_id > 1,
%         try
            add_to_message_box(handles, 'Starting x-validation. Please wait...');drawnow;
            set_button_state(handles, 'off', {''});        
            bbci = manage_parameters('get', 'bbci');
            data = manage_parameters('get', 'data');
            if exist('clab', 'var') && ~isempty(clab),
                data = reduce_channels(data, clab);
                restore_data = 0;
            end
            if exist('stopping', 'var') && ~isempty(stopping),
                restore_data = 0;
                if isfield(bbci.calibrate, 'early_stopping_fnc'),
                    bbci.calibrate = rmfield(bbci.calibrate, 'early_stopping_fnc');
                end
            end
            if iscell(bbci.calibrate.settings.model), %% HACK. Check this.
                bbci.calibrate.settings.model{1} = str2func(['@train_' sel_class{1}]);
            end
            bbci.calibrate.settings.reject_channels = get(handles.reject_channels_tick, 'value');
            bbci.calibrate.settings.reject_artifacts = get(handles.reject_artifacts_tick, 'value');
            [bbci, data] = bbci_calibrate(bbci,data);
            if restore_data,
                manage_parameters('set', 'data', data);
                manage_parameters('set', 'bbci', bbci);
                manage_parameters('update', 'state.trained', true);                
            end
            if get(handles.reject_artifacts_tick, 'value') & ~isempty(data.result.rejected_trials) & ~isnan(data.result.rejected_trials),
                add_to_message_box(handles, sprintf('Warning: %i (%0.2f%%) trial(s) rejected.', ...
                    length(data.result.rejected_trials), ...
                    length(data.result.rejected_trials)/length(data.mrk.desc)));
            end
            if get(handles.reject_channels_tick, 'value') & ~isempty(data.result.rejected_clab) & ~isnan(data.result.rejected_clab),
                deleted_channels = [sprintf('%s,', data.result.rejected_clab{1:end-1}), ...
                    data.result.rejected_clab{end}];
                add_to_message_box(handles, sprintf('Warning: %i channel(s) rejected [%s].', ...
                    length(data.result.rejected_clab), ...
                    deleted_channels));
            end
            add_to_message_box(handles, sprintf('Binary performance: %0.2f%%', ...
                100*mean([data.result.me(1,1), data.result.me(2,2)])));
            set_button_state(handles, 'on', {''});
%         catch
%             error = lasterror;
%             disp(error.message);
%             set_button_state(handles, 'on', {''});
%             add_to_message_box(handles, 'Something went wrong and I didn''t do xvalidation. Please check the command window for errors');
%         end
    else
        add_to_message_box(handles, 'No classifier selected...');
    end
else
    add_to_message_box(handles, 'Please initialize first, load data and select intervals...');
end


% --- Executes on button press in save_classifier_button.
function save_classifier_button_Callback(hObject, eventdata, handles)
% hObject    handle to save_classifier_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if check_state(handles, 3)
    try
        add_to_message_box(handles, 'Saving classifier. Please wait...');drawnow;
        set_button_state(handles, 'off', {''});
        bbci = manage_parameters('get', 'bbci');
        data = manage_parameters('get', 'data');
        bbci.calibrate.save.file = find_classifier_name(bbci.calibrate.save.file);
        bbci.feature.proc = {{@proc_selectChannels, data.cnt.clab}, bbci.feature.proc{:}};
        bbci = bbci_save(bbci);
        experiments = manage_parameters('get', 'experiment_settings');
        look_for_existing_files(handles, ...
            experiments.classifier_name, '.mat', 1, ...
            get(handles.today_only_classifier_tick, 'value'),handles.run_classifier_menu);        
        set_button_state(handles, 'on', {''});
        add_to_message_box(handles, 'Classifier written.');
    catch
        error = lasterror;
        disp(error.message);
        set_button_state(handles, 'on', {''});
        add_to_message_box(handles, 'Something went wrong and I didn''t save the classifier. Please check the command window for errors');
    end    
else
    add_to_message_box(handles, 'Please initialize first, load data and train a classifier.');
end

% --- Executes on selection change in choose_classifier_popup.
function choose_classifier_popup_Callback(hObject, eventdata, handles)
% hObject    handle to choose_classifier_popup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns choose_classifier_popup contents as cell array
%        contents{get(hObject,'Value')} returns selected item from choose_classifier_popup


% --- Executes during object creation, after setting all properties.
function choose_classifier_popup_CreateFcn(hObject, eventdata, handles)
% hObject    handle to choose_classifier_popup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on selection change in experiment_box.
function experiment_box_Callback(hObject, eventdata, handles)
% hObject    handle to experiment_box (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns experiment_box contents as cell array
%        contents{get(hObject,'Value')} returns selected item from experiment_box
handle_experiment_parameters(handles, 'update_exp');

% --- Executes during object creation, after setting all properties.
function experiment_box_CreateFcn(hObject, eventdata, handles)
% hObject    handle to experiment_box (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in simulate_tick.
function simulate_tick_Callback(hObject, eventdata, handles)
% hObject    handle to simulate_tick (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of simulate_tick

% --- Executes on button press in clear_button.
function clear_button_Callback(hObject, eventdata, handles)
% hObject    handle to clear_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
manage_parameters('reset', 'data');
manage_parameters('update', 'state.loaded', false);
manage_parameters('update', 'state.trained', false);
add_to_message_box(handles, 'Data cleared...');

% --- Executes on button press in run_experiment_button.
function run_experiment_button_Callback(hObject, eventdata, handles)
% hObject    handle to run_experiment_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
GB = manage_parameters('get', 'global_bbci');
state = manage_parameters('get', 'state');
ES = manage_parameters('get', 'experiment_settings');
bbci = manage_parameters('get', 'bbci');

if check_state(handles,1),
    if check_preflight_conditions(handles);
        switch get(handles.run_experiment_switch, 'UserData'),
            case 'stop'
%                 try
                    add_to_message_box(handles, 'Starting experiment...');
                    set(handles.run_experiment_switch,'UserData','run');
                    set(handles.run_experiment_button, 'string', 'Pause');
                    [run_exp run_id] = get_selected_item(handles.experiment_box);
                    run_exp = genvarname(run_exp{1});
                    set_button_state(handles, 'off', {'stop_experiment_button', 'run_experiment_button'});
                    ES.parameters.(run_exp).test = get(handles.simulate_tick, 'value');
                    opt.experiment = run_exp;
                    opt.parameters = ES.parameters.(run_exp);
                    if isfield(ES, 'aux'),
                        opt.aux = ES.aux;
                    end
                    opt.bbci = bbci;
                    if isfield(opt, 'aux') & isfield(opt.aux, 'custom_settings_folder'),
                        cust_file = [opt.aux.custom_settings_folder GB.Tp.Code '_pb_setup.m'];
                        if exist(cust_file, 'file') && isempty(strmatch('Calibration', run_exp)),
                            run(cust_file);
                            opt.parameters.filename = strcat(opt.parameters.filename, stored_set.file_suffix);
                            opt.parameters = set_defaults(stored_set, opt.parameters);
                        end
                    end
                    if ~opt.parameters.test,
                        start_recording(handles, opt.parameters.filename);
                        if ES.requires_online(run_id),
                            exp_opt = start_classifier(handles);
                            if isfield(exp_opt, 'early_stopping'),
                                opt.parameters.early_stopping_enable = exp_opt.early_stopping.active;
                                opt.parameters.rank_diff_thresholds = exp_opt.early_stopping.param;
                            end
                        end
                        pause(5);
                    end
                    overload_gui_funcs('run_experiments', state.study, handles, opt);
                    set_button_state(handles, 'on', {''});
                    add_to_message_box(handles, 'Experiment started...');
%                 catch
%                     error = lasterror;
%                     disp(error.message);
%                     set_button_state(handles, 'on', {''});
%                     set(handles.run_experiment_switch,'UserData','stop');
%                     set_run_button_text(handles);
%                     ppTrigger(bbci.quit_condition.marker); %try to close classifier and recorder
%                     stop_recording(handles);
%                     add_to_message_box(handles, 'I tried, but the experiment would not run. Please check the command window');
%                 end
            case 'pause'
                add_to_message_box(handles, 'Resuming experiment...');
                pyff('play');
                set(handles.run_experiment_switch,'UserData','run');
                set_run_button_text(handles);
            case 'run'
                add_to_message_box(handles, 'Pausing experiment...');
                pyff('stop');
                set(handles.run_experiment_switch,'UserData','pause');
                set_run_button_text(handles);
        end
    else
        add_to_message_box(handles, 'Experiment cancelled on user request.');
    end
end


% --- Executes on button press in stop_experiment_button.
function stop_experiment_button_Callback(hObject, eventdata, handles)
% hObject    handle to stop_experiment_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set_button_state(handles, 'on', {''});
set(handles.run_experiment_switch,'UserData','stop');
set_run_button_text(handles);
% stop_recording(handles);
close_images_but_not_gui();
try,
    pyff('quit');
catch,
    % no biggie
end

% --- Executes on selection change in run_classifier_menu.
function run_classifier_menu_Callback(hObject, eventdata, handles)
% hObject    handle to run_classifier_menu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns run_classifier_menu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from run_classifier_menu


% --- Executes during object creation, after setting all properties.
function run_classifier_menu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to run_classifier_menu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on button press in stop_classifier_button.
function stop_classifier_button_Callback(hObject, eventdata, handles)
% hObject    handle to stop_classifier_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
ppTrigger(254);


% --- Executes on button press in today_only_classifier_tick.
function today_only_classifier_tick_Callback(hObject, eventdata, handles)
% hObject    handle to today_only_classifier_tick (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of today_only_classifier_tick
experiments = manage_parameters('get', 'experiment_settings');
look_for_existing_files(handles, ...
        experiments.classifier_name, '.mat', 1, ...
        get(handles.today_only_classifier_tick, 'value'), ...
        handles.run_classifier_menu); 



% --- Executes on selection change in channel_selection_list_box.
function channel_selection_list_box_Callback(hObject, eventdata, handles)
% hObject    handle to channel_selection_list_box (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns channel_selection_list_box contents as cell array
%        contents{get(hObject,'Value')} returns selected item from channel_selection_list_box


% --- Executes during object creation, after setting all properties.
function channel_selection_list_box_CreateFcn(hObject, eventdata, handles)
% hObject    handle to channel_selection_list_box (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function number_channel_box_Callback(hObject, eventdata, handles)
% hObject    handle to number_channel_box (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of number_channel_box as text
%        str2double(get(hObject,'String')) returns contents of number_channel_box as a double


% --- Executes during object creation, after setting all properties.
function number_channel_box_CreateFcn(hObject, eventdata, handles)
% hObject    handle to number_channel_box (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
str = {'Number of channels'};
for i = 2:64,
    str{i} = i;
end
set(hObject, 'string', str, 'value', 16);


% --- Executes on button press in run_selection_button.
function run_selection_button_Callback(hObject, eventdata, handles)
% hObject    handle to run_selection_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if check_state(handles,3),
    %     if ask_for_correct_ival(handles),
    method = get_selected_item(handles.channel_selection_list_box);
    nrCh = get_selected_item(handles.number_channel_box);
    nrCh = str2num(nrCh{1});
    set_button_state(handles, 'off', {''});
    try
        add_to_message_box(handles, 'Starting channel selection...');drawnow;
        data = manage_parameters('get', 'data');
        featPerChan = size(data.feature.x, 1)/length(data.result.cfy_clab);
        
        switch method{1},
            case 'SWLDA - featurewise',
                selected = proc_stepwiseChannelSelect(...
                    data.feature.x, data.feature.y, ...
                    'featPChan' , featPerChan, ...
                    'maxChan', nrCh, ...
                    'visualize', 0,...
                    'channelwise', 0);

            case 'SWLDA - channelwise',
                selected = proc_stepwiseChannelSelect(...
                    data.feature.x, data.feature.y, ...
                    'featPChan' , featPerChan, ...
                    'maxChan', nrCh, ...
                    'visualize', 0,...
                    'channelwise', 1);
        end
        reset_channel_names(handles);
        set(handles.channel_names_listbox, 'value', selected);
        update_nr_chan_selected(handles);
        add_to_message_box(handles, ['Selected ' num2str(length(selected)) ' channels.']);
        set_button_state(handles, 'on', {''});
    catch
        error = lasterror;
        disp(error.message);
        set_button_state(handles, 'on', {''});
        add_to_message_box(handles, 'Something went wrong. I''m sorry!');
    end
else
    add_to_message_box(handles, 'Please initialize, load data and train any classifier first.');
end


% --- Executes on button press in show_channels_button.
function show_channels_button_Callback(hObject, eventdata, handles)
% hObject    handle to show_channels_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if check_state(handles,2),
    clab = get(handles.channel_names_listbox, 'string')';
    sel_clab = get(handles.channel_names_listbox, 'value')';
    mnt = mnt_setElectrodePositions(clab);
    colOrder = [0.9 0 0.9; 0.4 0.57 1];
    labelProps = {'FontName','Times','FontSize',8,'FontWeight','normal'};
    markerProps = {'MarkerSize', 15, 'MarkerEdgeColor','k','MarkerFaceColor',[1 1 1]};
    highlightProps = {'MarkerEdgeColor','k','MarkerFaceColor',colOrder(1,:),...
        'LineWidth',2};
    linespec = {'Color' 'k' 'LineWidth' 2};
    refProps = {'FontSize', 8, 'FontName', 'Times','BackgroundColor',[.8 .8 .8],'HorizontalAlignment','center','Margin',2};

    opt = {'showLabels',1,'labelProps',labelProps,'markerProps',...
        markerProps,'markChans',clab(sel_clab),'markMarkerProps',...
        highlightProps,'linespec',linespec,'ears',1,'reference','nose', ...
        'referenceProps', refProps};

    % Draw the stuff
    fig = figure;
    H= drawScalpOutline(mnt, opt{:});
    set(fig, 'MenuBar', 'none');
    set(gca,'box','on')
    set(gca, 'Position', [0 0 1 1]);
    pos = get(gcf,'Position');
    axis off;
end

% --- Executes on button press in use_channels_button.
function use_channels_button_Callback(hObject, eventdata, handles)
% hObject    handle to use_channels_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
GB = manage_parameters('get', 'global_bbci');

if check_state(handles,2),
    try,
        add_to_message_box(handles, 'Now switching to selected channels');
        set_button_state(handles, 'off', {''});
        [clab clab_id] = get_selected_item(handles.channel_names_listbox);
        data = manage_parameters('get', 'data');
        
        data.cnt = proc_selectChannels(data.cnt, clab);
        data.mnt =mnt_restrictMontage(data.mnt, clab);
        data = rmfields(data, {'feature', 'result', 'previous_settings'});
        data.isnew = 1;
        data = manage_parameters('set', 'data', data);
        
        reset_channel_names(handles);
        set(handles.channel_names_listbox, 'value', [1:length(clab_id)]);
        update_nr_chan_selected(handles);
        
        ES = manage_parameters('get', 'experiment_settings');
        
        if isfield(ES, 'aux') && isfield(ES.aux, 'sigserv_template'),
            template = ES.aux.sigserv_template;
            target = [GB.dir 'online\communication\signalserver\config_sigserv_' GB.Tp.Code '.xml'];
            
            fid = fopen(template, 'r');
            str = fread(fid, [1 inf], 'uint8=>char');
            fclose(fid);
            
            chans = '';
            for i = 1:length(clab),
                chans = [chans sprintf('<ch nr="%i" name="%s" type="eeg" />\r', i, clab{i})];
            end
            
            str = sprintf(str, GB.Tp.Code, ES.aux.gtec_serial,length(clab), chans);
            
            fid = fopen(target, 'w');
            fwrite(fid, str);
            fclose(fid);
            add_to_message_box(handles, 'New signalserver file written');          
        end
        set_button_state(handles, 'on', {''});  
    catch,
        error = lasterror;
        disp(error.message);
        set_button_state(handles, 'on', {''});
        add_to_message_box(handles, 'Oops, something went wrong. No setup file written.');   
    end
end

% --- Executes on selection change in channel_names_listbox.
function channel_names_listbox_Callback(hObject, eventdata, handles)
% hObject    handle to channel_names_listbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns channel_names_listbox contents as cell array
%        contents{get(hObject,'Value')} returns selected item from channel_names_listbox
update_nr_chan_selected(handles);

% --- Executes during object creation, after setting all properties.
function channel_names_listbox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to channel_names_listbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on selection change in parameter_name_list.
function parameter_name_list_Callback(hObject, eventdata, handles)
% hObject    handle to parameter_name_list (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns parameter_name_list contents as cell array
%        contents{get(hObject,'Value')} returns selected item from parameter_name_list
handle_experiment_parameters(handles, 'update');

% --- Executes during object creation, after setting all properties.
function parameter_name_list_CreateFcn(hObject, eventdata, handles)
% hObject    handle to parameter_name_list (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function parameter_value_box_Callback(hObject, eventdata, handles)
% hObject    handle to parameter_value_box (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of parameter_value_box as text
%        str2double(get(hObject,'String')) returns contents of parameter_value_box as a double


% --- Executes during object creation, after setting all properties.
function parameter_value_box_CreateFcn(hObject, eventdata, handles)
% hObject    handle to parameter_value_box (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in use_parameter_button.
function use_parameter_button_Callback(hObject, eventdata, handles)
% hObject    handle to use_parameter_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handle_experiment_parameters(handles, 'save');



% --- Executes on button press in amp_button_gtec.
function amp_button_gtec_Callback(hObject, eventdata, handles)
% hObject    handle to amp_button_gtec (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global acquire_func;

% Hint: get(hObject,'Value') returns toggle state of amp_button_gtec
set([handles.start_signalserver_button, handles.start_impedance_button], 'visible', 'on');
set([handles.start_bv_button], 'visible', 'off');
acquire_func = @acquire_sigserv;
% assignin('base', 'tmp', 1200);
% evalin('base', 'bbci.original_fs = tmp; clear tmp;');
add_to_message_box(handles, 'Switching to g.Tec.');

% --- Executes on button press in amp_button_bv.
function amp_button_bv_Callback(hObject, eventdata, handles)
% hObject    handle to amp_button_bv (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global acquire_func;

% Hint: get(hObject,'Value') returns toggle state of amp_button_bv
set([handles.start_signalserver_button, handles.start_impedance_button], 'visible', 'off');
set([handles.start_bv_button], 'visible', 'on');
acquire_func = @acquire_bv;
add_to_message_box(handles, 'Switching to BrainAmp.');

% --- Executes on button press in advanced_toggle.
function advanced_toggle_Callback(hObject, eventdata, handles)
% hObject    handle to advanced_toggle (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of advanced_toggle
if get(hObject, 'Value'),
    set([handles.channel_select_panel, handles.images_panel, handles.debug_panel], 'Visible', 'on');
else
    set([handles.channel_select_panel, handles.images_panel, handles.debug_panel], 'Visible', 'off');
end

% --- Executes on button press in start_pyff_button.
function start_pyff_button_Callback(hObject, eventdata, handles)
% hObject    handle to start_pyff_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global IO_ADDR;
set_general_port_fields('localhost');
opt.dir = 'E:\svn\pyff\src\';
opt.bvplugin = 0;
opt.l = 'debug';
opt.a = 'E:\svn\p300_photobrowser';
% opt.a = 'C:\Dokumenten\SVN\TOBI_app';
opt.gui = 0;
opt.output_protocol = 'tobixml';
opt.parport = dec2hex(IO_ADDR);
pyff('startup', opt);
manage_parameters('update', 'state.pyff_started', true);
add_to_message_box(handles, 'Pyff started. Please check');

% --- Executes on button press in start_signalserver_button.
function start_signalserver_button_Callback(hObject, eventdata, handles)
% hObject    handle to start_signalserver_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

GB = manage_parameters('get', 'global_bbci');
if check_state(handles,1),
    personal_file = [GB.dir 'online\communication\signalserver\config_sigserv_' GB.Tp.Code '.xml'];
    if exist(personal_file, 'file')
        start_signalserver(personal_file);
    else
        start_signalserver('server_config_test.xml');
    end
    manage_parameters('update', 'state.sigserv_started', true);
    add_to_message_box(handles, 'Signal server started. Please check!');
else
    add_to_message_box(handles, 'Please initialize first.');
end

% --- Executes on button press in start_impedance_button.
function start_impedance_button_Callback(hObject, eventdata, handles)
% hObject    handle to start_impedance_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
GB = manage_parameters('get', 'global_bbci');
if check_state(handles,1),
    personal_file = ['config_sigserv_' GB.Tp.Code '.xml'];
    if exist(personal_file, 'file')
        signalserver_impedance(personal_file);
    else
        signalserver_impedance('server_config_test.xml');
    end
else
    add_to_message_box(handles, 'Please initialize first.');
end

% --- Executes on button press in dump_memory_button.
function dump_memory_button_Callback(hObject, eventdata, handles)
% hObject    handle to dump_memory_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
manage_parameters('dump');


% --- Executes on button press in unlock_menu_button.
function unlock_menu_button_Callback(hObject, eventdata, handles)
% hObject    handle to unlock_menu_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set_button_state(handles, 'on', {});
evalin('base', 'dbquit(''all'');');


% --- Executes during object creation, after setting all properties.
function unlock_menu_button_CreateFcn(hObject, eventdata, handles)
% hObject    handle to unlock_menu_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


% --- Executes on button press in test_performance_button.
function test_performance_button_Callback(hObject, eventdata, handles)
% hObject    handle to test_performance_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
clab = get_selected_item(handles.channel_names_listbox);
if check_state(handles, 2)
    if length(clab) >= 2,
        train_classifier_button_Callback('', '', handles, clab, false);
    else
        add_to_message_box(handles, 'Select at least 2 channels.');
    end
else
    add_to_message_box(handles, 'Please initialize and load data first.');
end

% --- Executes on button press in adaptation_checkbox.
function adaptation_checkbox_Callback(hObject, eventdata, handles)
% hObject    handle to adaptation_checkbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of adaptation_checkbox

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Non callback functions (helper functions)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function start_recording(handles, filename),
GB = manage_parameters('get', 'global_bbci');
if get(handles.amp_button_bv, 'value'),
    % this is easy
    rec_opt.impedances = 0;
    rec_opt.append_VP_CODE = 1;
    bvr_startrecording(filename, rec_opt);
else
    % gTec sucks bigtime!
    signalServer_startrecoding([filename GB.Tp.Code]);
end

function stop_recording(handles),
% bbci = manage_parameters('get', 'bbci');
% % ppTrigger(bbci.quit_condition.marker);
% pause(1);
% if get(handles.amp_button_bv, 'value'),
%     bvr_sendcommand('stoprecording');
% end

function exp_opt = start_classifier(handles)
experiments = manage_parameters('get', 'experiment_settings');
GB = manage_parameters('get', 'global_bbci');
exp_opt = struct();

if check_state(handles,1),
    classifier = get_selected_item(handles.run_classifier_menu);
    if ~strcmp(classifier, 'Initialize first') && ~isempty(classifier) && ~strcmp(classifier, 'No files found.'),
        cls = load([GB.RawDir filesep classifier{1} '.mat']);  
        if get(handles.amp_button_gtec, 'value'),
            cls.source.acquire_fcn = @bbci_acquire_sigserv;
        else
            cls.source.acquire_fcn = @bbci_acquire_bv;
        end
        if get(handles.adaptation_checkbox, 'value'),
            cls.adaptation.active = 1;
        else
            cls.adaptation.active = 0;
        end
        if get(handles.stopping_checkbox, 'value'),
            if isfield(cls, 'feedback') && isfield(cls.feedback, 'early_stopping'),
                exp_opt.early_stopping.active = true;
                exp_opt.early_stopping.param = cls.feedback.early_stopping.param;
                add_to_message_box(handles, 'Early stopping parameters found and loaded.');
            else
                exp_opt.early_stopping.active = false;
                add_to_message_box(handles, 'No early stopping parameters found.');                
            end
        end
        save([GB.TmpDir filesep 'tmp_classifier'], '-struct', 'cls');
        
        cmd_init= sprintf('BBCI.Tp.Code= ''%s''; BBCI.Tp.Dir= ''%s'';set_general_port_fields(''localhost'');general_port_fields.feedback_receiver = ''pyff'';', GB.Tp.Code, GB.Tp.Dir);
        bbci_cfy= [GB.TmpDir filesep 'tmp_classifier.mat'];
        cmd_bbci= ['dbstop if error; bbci = load(''' bbci_cfy '''); bbci_apply(bbci);'];
        system(['matlab -nosplash -nojvm -r "' cmd_init cmd_bbci '; exit;" &']);
    else
        add_to_message_box(handles, 'No valid classifier selected. Maybe you should train one?');
    end
end


function handle_experiment_parameters(handles, action, varargin);
experiments = manage_parameters('get', 'experiment_settings');
PN = experiments.editable_params;
RO = experiments.requires_online;
RA = experiments.requires_adaptation;
RS = experiments.requires_stopping;
PV = experiments.parameters;
has_params = [handles.parameter_value_box, ...
    handles.parameter_name_list, ...
    handles.use_parameter_button];
is_online = [handles.adaptation_checkbox, ...
    handles.stopping_checkbox, ...
    handles.today_only_classifier_tick, ...
    handles.run_classifier_menu, ...
    handles.text10];

switch action
    case 'init'
        handle_experiment_parameters(handles, 'update_exp');

    case 'update'
        [exp exp_id] = get_selected_item(handles.experiment_box);
        [param_name param_id] = get_selected_item(handles.parameter_name_list);      
        set(handles.parameter_value_box, 'string', ...
            PV.(genvarname(exp{1})).(param_name{1}));

    case 'save'
        [exp exp_id] = get_selected_item(handles.experiment_box);
        [param_name param_id] = get_selected_item(handles.parameter_name_list);
        value = get(handles.parameter_value_box, 'string');
        if isempty(str2num(value)),
            experiments.parameters.(genvarname(exp{1})).(param_name{1}) = value;
        else
            experiments.parameters.(genvarname(exp{1})).(param_name{1}) = str2num(value);
        end
        manage_parameters('set', 'experiment_settings', experiments);

    case 'update_exp'
        [exp exp_id] = get_selected_item(handles.experiment_box);
        if ~isempty(PN{exp_id}),
            set(has_params, 'Visible', 'on');
            set(handles.parameter_name_list, 'string', PN{exp_id}, 'value', 1);
            handle_experiment_parameters(handles, 'update');
        else
            set(has_params, 'Visible', 'off');
        end
        if RO(exp_id),
            set(is_online, 'Visible', 'on');
        else
            set(is_online, 'Visible', 'off');
        end
        set(handles.adaptation_checkbox, 'value', RA(exp_id));
        set(handles.stopping_checkbox, 'value', RS(exp_id));
end

function close_images_but_not_gui()
fh=findall(0,'Type','Figure');
for i = 1:length(fh),
    if ~strcmp(get(fh(i), 'name'), 'erp_gui'),
        close(fh(i));
    end
end

function data = reduce_channels(data, clab),
    data.cnt = proc_selectChannels(data.cnt, clab);
    data.mnt = mnt_restrictMontage(data.mnt, clab);
    data.isnew = 1;
    data = rmfield(data,{'feature', 'result', 'previous_settings'});
    
function [value index] = get_selected_item(hObject),
    index = get(hObject, 'value');
    content = get(hObject, 'string');
    value = content(index);
    
function val_file = find_classifier_name(handles),
    global BBCI
    bbci = manage_parameters('get', 'bbci');
    base_file = bbci.calibrate.save.file;
    val_file = base_file;
    counter = 1;
    while exist(strcat(BBCI.Tp.Dir, val_file, '.mat'), 'file'),
        val_file = sprintf('%s_%02d', base_file, counter);
        counter = counter+1;
    end

function reached = check_state(handles, level),
    state = manage_parameters('get', 'state');
    switch level
        case 1,
            reached = state.inited;
        case 2,
            reached = state.inited && state.loaded;
        case 3,
            reached = state.inited && state.loaded && state.trained;
    end
    
function set_run_button_text(handles),
switch get(handles.run_experiment_switch, 'UserData'),
    case 'stop'
        set(handles.run_experiment_button, 'string', 'Run experiment');
    case 'pause'
        set(handles.run_experiment_button, 'string', 'Resume');
    case 'run'
        set(handles.run_experiment_button, 'string', 'Pause');
end

function set_button_state(handles, state, exclude),
flds = fieldnames(handles);
exclude = {exclude{:}, 'unlock_menu_button'};
for i = 1:length(flds),
    if strcmp(get(handles.(flds{i}), 'type'), 'uicontrol') && isempty(intersect(flds{i}, exclude)),
        set(handles.(flds{i}), 'enable', state);
    end
end
if strcmp(state, 'off'), 
    set(handles.unlock_menu_button, 'visible', 'on');
else
    set(handles.unlock_menu_button, 'visible', 'off');
end
drawnow;

function add_to_message_box(handles, str),
    curMes = get(handles.message_box, 'string');
    newMes = sprintf('%s\r%s', str, curMes);
    set(handles.message_box, 'string', newMes);
    
function files = look_for_existing_files(handles, names, ext, individual, today_only, hObject),
GB = manage_parameters('get', 'global_bbci');
if ~isempty(GB.Tp.Code),
%     experiments = manage_parameters('get', 'experiment_settings');
    set(handles.file_list_box, 'value', 1);
    val_file = names;
    if today_only,
        if GB.Tp.Dir(end) == '\' || GB.Tp.Dir(end) == '/'
            [dum d(1).name] = fileparts(GB.Tp.Dir(1:end-1));
        else
            [dum d(1).name] = fileparts(GB.Tp.Dir);
        end
        val_id = 1;
    else
        d = dir(GB.RawDir);
        val_id = strmatch([GB.Tp.Code '_'], {d(:).name});
    end
    % select valid dirs and sort
    d = d(val_id);
    [dum id] = sort({d(:).name});
    d = d(fliplr(id));
    files = {};
    for d_id = 1:length(d),
        d2 = dir([GB.RawDir d(d_id).name filesep '*' ext]);
        for f_id = 1:length(val_file),
            val_f_id = strmatch(val_file{f_id}, {d2(:).name});
            if ~isempty(val_f_id),
                if individual,
                    val_f_id = flipud(val_f_id);
                    for j = 1:length(val_f_id),
                        files{length(files)+1} = [d(d_id).name filesep d2(val_f_id(j)).name(1:end-4)];
                    end
                else
                    files{length(files)+1} = [d(d_id).name filesep d2(val_f_id(1)).name(1:end-4) '*'];
                end
            end
        end
    end
    if isempty(files),
        files = {'No files found'};
    end
    if exist('hObject', 'var'),
        % update the respective field
        set(hObject, 'string', files);
    end
end

function reset_channel_names(handles),
if check_state(handles,2),
    data = manage_parameters('get', 'data');
    clab_loaded = data.cnt.clab;
    set(handles.channel_names_listbox, 'value', 1);
    set(handles.channel_names_listbox, 'string', clab_loaded);
end

function update_nr_chan_selected(handles),
str = sprintf('%i of %i channels selected', length(get(handles.channel_names_listbox, 'value')), length(get(handles.channel_names_listbox, 'string')));
set(handles.selected_channels_text, 'string', str);

% store any variable inside the gui, to reduce redundant function calls
function parameters = manage_parameters(action, varargin),
    persistent internal_memory;
    switch action
        case 'set', 
            internal_memory.(varargin{1}) = varargin{2}; 
            parameters = internal_memory.(varargin{1});
        case 'get', 
            parameters = internal_memory.(varargin{1});
        case 'reset', 
            if isempty(varargin),
                internal_memory = [];
            else 
                try
                    internal_memory = rmfield(internal_memory, varargin{1});
                end
            end
        case 'update'
            % check if we have to update a struct
            names = regexp(varargin{1}, '\.', 'split');
            name = strcat('internal_memory', sprintf('.%s', names{:}));
            try
                eval([name ';']);
                eval([name '= varargin{2};']);
            catch
                error('I can only update existing variables and fields. Otherwise use set.');
            end            
        case 'dump',
            assignin('base', 'gui_internals', internal_memory);
        otherwise,
            warning('Invalid query in internal storage.');
    end





% --- Executes on button press in reject_artifacts_tick.
function reject_artifacts_tick_Callback(hObject, eventdata, handles)
% hObject    handle to reject_artifacts_tick (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of reject_artifacts_tick


% --- Executes on button press in stopping_checkbox.
function stopping_checkbox_Callback(hObject, eventdata, handles)
% hObject    handle to stopping_checkbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of stopping_checkbox


% --- Executes on selection change in preflight_pyff.
function preflight_pyff_Callback(hObject, eventdata, handles)
% hObject    handle to preflight_pyff (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns preflight_pyff contents as cell array
%        contents{get(hObject,'Value')} returns selected item from preflight_pyff


% --- Executes during object creation, after setting all properties.
function preflight_pyff_CreateFcn(hObject, eventdata, handles)
% hObject    handle to preflight_pyff (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in preflight_sigserv.
function preflight_sigserv_Callback(hObject, eventdata, handles)
% hObject    handle to preflight_sigserv (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns preflight_sigserv contents as cell array
%        contents{get(hObject,'Value')} returns selected item from preflight_sigserv


% --- Executes during object creation, after setting all properties.
function preflight_sigserv_CreateFcn(hObject, eventdata, handles)
% hObject    handle to preflight_sigserv (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in preflight_bv.
function preflight_bv_Callback(hObject, eventdata, handles)
% hObject    handle to preflight_bv (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns preflight_bv contents as cell array
%        contents{get(hObject,'Value')} returns selected item from preflight_bv


% --- Executes during object creation, after setting all properties.
function preflight_bv_CreateFcn(hObject, eventdata, handles)
% hObject    handle to preflight_bv (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in start_bv_button.
function start_bv_button_Callback(hObject, eventdata, handles)
% hObject    handle to start_bv_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
system('c:\Vision\Recorder\Recorder.exe &');
manage_parameters('update', 'state.bv_started', true);
add_to_message_box(handles, 'Attempted to start the BV recorder.');

function pf_confirm = check_preflight_conditions(handles),
    state = manage_parameters('get', 'state');
    % set popup handles
    panel = [handles.check_panel handles.mask_text];
    pyff_items = [handles.preflight_pyff, handles.preflight_text_pyff];
    bv_items = [handles.preflight_bv, handles.preflight_text_bv];
    sigserv_items = [handles.preflight_sigserv, handles.preflight_text_sigserv];
    all = [panel pyff_items bv_items sigserv_items];
    set(all, 'Visible', 'off');
    if state.pyff_started && state.sigserv_started && get(handles.amp_button_gtec, 'value'),
        pf_confirm = 1;
        return;
    elseif state.pyff_started && state.bv_started && get(handles.amp_button_bv, 'value'),
        pf_confirm  = 1; 
        return;
    end
    % do the actual checks
    if ~state.pyff_started,
        set(pyff_items, 'Visible', 'on');
    end    
    if get(handles.amp_button_gtec, 'value') && ~state.sigserv_started,
        set(sigserv_items, 'Visible', 'on');
    end
    if get(handles.amp_button_bv, 'value'),
        set(bv_items, 'Visible', 'on');
    end
    set(panel, 'Visible', 'on');
    uiwait(gcf);
    set(all, 'Visible', 'off');
    pf_confirm = get(handles.preflight_button, 'UserData');
    set(handles.preflight_button, 'UserData',0);

% --- Executes on button press in preflight_button.
function preflight_button_Callback(hObject, eventdata, handles)
% hObject    handle to preflight_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
state = manage_parameters('get', 'state');
set(hObject,'UserData',1);
if ~state.pyff_started,
    switch get(handles.preflight_pyff, 'value'),
        case 1,
            start_pyff_button_Callback([], [], handles);
        case 2, 
            manage_parameters('update', 'state.pyff_started', true);
    end
end
if get(handles.amp_button_gtec, 'value') && ~state.sigserv_started,
    switch get(handles.preflight_sigserv, 'value'),
        case 1,
            start_signalserver_button_Callback([], [], handles);
        case 2, 
            manage_parameters('update', 'state.sigserv_started', true);
    end
end
if get(handles.amp_button_bv, 'value') && ~state.bv_started,
    switch get(handles.preflight_bv, 'value'),
        case 1,
            start_bv_button_Callback([], [], handles);
        case 2, 
            manage_parameters('update', 'state.bv_started', true);
    end
end
set(handles.check_panel, 'Visible', 'off');
uiresume(gcbf);


% --- Executes on button press in preflight_cancel_button.
function preflight_cancel_button_Callback(hObject, eventdata, handles)
% hObject    handle to preflight_cancel_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.check_panel, 'Visible', 'off');
set(handles.preflight_button, 'UserData',0);
uiresume(gcbf);


% --- Executes on button press in data_folder_button.
function data_folder_button_Callback(hObject, eventdata, handles)
% hObject    handle to data_folder_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
GB = manage_parameters('get', 'global_bbci');
if check_state(handles, 1),
    file = get_selected_item(handles.file_list_box);
    if length(file) > 1,
        add_to_message_box(handles, 'Multiple files selected. Going to folder of newest one');
    end
    [directory file] = fileparts(file{1});
    if isunix,
        system(sprintf('open %s', [GB.RawDir filesep directory]));
    else
        winopen([GB.RawDir filesep directory]);
    end
    add_to_message_box(handles, 'Directory opened.');    
else
    add_to_message_box(handles, 'Please initialize first');
end


% --- Executes during object creation, after setting all properties.
function simulate_tick_CreateFcn(hObject, eventdata, handles)
% hObject    handle to simulate_tick (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
