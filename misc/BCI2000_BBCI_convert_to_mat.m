function BCI2000_BBCI_convert_to_mat(folder)
%BCI2000_CONVERT_TO_MAT - convert BCI2000 .dat files to BBCI format
%
%Synopsis:
% BCI2000_BBCI_convert_to_mat(folder)
% 
%
%Arguments:
% folder -   folder name containing .dat files
%
%Returns:
% creates folder and saves the converted 
% .mat files in BTB.MatDir/Mat/BCI2000/folder
% Note:
% Requires load_bcidat mex function delivred with BCI2000 package
% 
% Okba Bekhelifi, LARESI, USTO-MB <okba.bekhelifi@univ-usto.dz>
% 02-2017
global BTB

% check if 'load_bcidat' is added in the path
if exist('load_bcidat','file') == 0 
    error('BCI2000 load function is not found');
end

if exist('BTB','var') == 0
    if exist('init_bbci','file') == 2 
%         the author's own script to run BBCI
        init_bbci;
    else
        error('run BBCI with startup_bbci_toolbox first');
    end
end

foldertmp = fullfile(BTB.DataDir, 'Raw', ['BCI2000\' folder]);
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
%  format states from .dat to a conveniet mrk structure
%  usinge function thutils_BCI20000_getmrk
    mrk = utils_BCI2000_getmrk(parameters, states);
%   create mnt   
    mnt = mnt_setElectrodePositions(cnt.clab);  
    mnt = mnt_setGrid(mnt, 'XXL');
    % save in matlab format
    file_saving_name = fullfile(BTB.DataDir, 'Mat', ['BCI2000\' folder '\' eegFiles{file}{1,1}]);
    file_saveMatlab(file_saving_name, cnt, mrk, mnt);
end
end

