function BCI2000_BBCI_convert_to_mat(folder)
% Okba BEKHELIFI - USTO-MB, <okba.bekhelifi@univ-usto.dz>
% Convert .dat BCI2000 files to BBCI format stored in a folder to mat files
% Input : folder : folder where data is stored
% created : 31/01/2017
% last modified : -- -- --
global BTB
if exist('BTB','var') == 0
    init_bbci;
end

foldertmp = fullfile(BTB.DataDir, 'Raw', ['BCI2000/' folder]);
files = dir([foldertmp '\*.dat']);
eegFiles = {files.name};
eegFiles = cellfun(@(s) strsplit(s, '.dat'), eegFiles, 'UniformOutput', false);

for file = 1:length(eegFiles)
   
    filepath = [foldertmp '\' eegFiles{file}{1,1}];
    [signal, states, parameters, total_samples] = load_bcidat(filepath);
%     cnt
    cnt.clab = parameters.ChannelNames.Value';
    cnt.fs = parameters.SamplingRate.NumericValue;
%   this value need to be changed for other BCI paradigms
    cnt.title = 'P300-Speller';
    cnt.T = total_samples;
    cnt.yUnit = 'µV';
    cnt.origClab = cnt.clab;
    cnt.file = filepath;
    cnt.x = signal;
    cnt.history = '';
%     mrk
    mrk = utils_BCI2000_getmrk(parameters, states);
    mnt = mnt_setElectrodePositions(cnt.clab);    
    % save in matlab format
    file_saving_name = fullfile(BTB.DataDir, 'Mat', ['BCI2000/' folder '/' str_remove_points(eegFiles{file}{1,1})]);
    file_saveMatlab(file_saving_name, cnt, mrk, mnt);
end
end

