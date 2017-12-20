function bbci_trigger_lsl(value, varargin)
%BBCI_TRIGGER_LSL Sends triggers using LabStreaminglayer
%   Sends trigger using the marker stream outlet defined in the
%   labstreaminglayer
%
% value     trigger value, numeric or 'init' or 'close' case
% varargin  the argument given bbci_trigger: BTB.Acq.TriggerParam{:}. 
%           In any case it should contain an LSL stream outlet of the 
%           marker stream. 

% NOTE:     The case that bbci.trigger.param{:} contains the lsl
%           stream is not enough because we dont have access to bbci struct
%           in this function in order to close the connection. 

% 11-2015 Jan Boelts


global BTB

if ischar(value) && strcmp(value, 'init'),
    if ~isdir('liblsl-Matlab')
        error('LSL Toolbox is not on the path. add it via addpath(genpath(''path_to_LSL/liblsl-Matlab''))')
    end
    % open LSL library to check for marker stream
    lib = lsl_loadlib();
    mrks = lsl_resolve_byprop(lib, 'name', 'MyMarkerStream', 1, 1);
    % if there is no marker stream, then open one and save it in global BTB
    % structure.
    if isempty(mrks)
        source_id = ['sourceID' num2str(randi(50000))];
        mrk_info = lsl_streaminfo(lib,'MyMarkerStream','Markers',1,1,'cf_string',source_id);
        % get the lsl stream outlet and save it as well as the lsl info object in BTB struct
        BTB.Acq.TriggerParam = {lsl_outlet(mrk_info), mrk_info};
        BTB.Acq.TriggerFcn = @bbci_trigger_lsl; 
        BTB.Acq.LSLsourceID = source_id; 
        fprintf(['Started LSL marker stream with source id ' source_id '\n']);
    else
        % if there is a stream it has to be closed because otherwise the
        % acquire function might connect to the wrong stream.
        error(['There is a markerstream with ID ' BTB.Acq.LSLsourceID ' on the network, use bbci_trigger(''close'') first!']);
    end
elseif ischar(value) && strcmp(value, 'close'),
    % try to close LSL marker stream
    try
        BTB.Acq.TriggerParam{1}.delete();
        BTB.Acq.TriggerParam{2}.delete();

    catch
        warning('There is no BTB struct or no LSL Markerstream with name MyMarkerStream to close.');
    end
    
elseif isnumeric(value)
    % hack to meet the format of the lsl marker stream and mimic the pp
    % marker format: 'S <markervalue>'
    marker = cat(2, 'S ', num2str(value));
    % In case someone only sets bbci.trigger.fcn = @bbci_trigger_lsl
    if isempty(varargin),
        error('LSL marker stream was not set up correcty. Set BTB.Acq.TriggerFcn = @bbci_trigger_lsl and use ''bbci_trigger(''init'')'' ');
    end
    % push sample to marker stream outlet
    try
        varargin{1}.push_sample({marker});
    catch
        error('LSL marker stream was not set up correcty. First use ''bbci_trigger(''init'')'', then ''bbci_trigger(value)''');
    end
else
    warning('The trigger has to be numeric or ''init'' or ''close'' : no trigger was sent')
end
end
