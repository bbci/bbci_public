
function OV_BBCI_convert_to_mat(folder)
% Okba BEKHELIFI - USTO-MB, <okba.bekhelifi@univ-usto.dz>
% Convert vhdr EEG files stored in a folder to mat files
% Input : folder : folder where data is stored
% created : 06/10/2016
% last modifies : -- -- --
if exist('BTB','var') == 0
    init_bbci;
end

global BTB
foldertmp = fullfile(BTB.DataDir, 'Raw', ['OV/mvep/' folder]);
files = dir([foldertmp '\*.vhdr']);
eegFiles = {files.name};
eegFiles = cellfun(@(s) strsplit(s, '.'), eegFiles, 'UniformOutput', false);

for file = 1:length(eegFiles)
    filepath = [foldertmp '/' eegFiles{file}{1,1}];
    [cnt, mrk_orig, hdr] = file_readBV(filepath);
    
    stimDef= {31:36, 11:16; 'target', 'nontarget'};
    mrk = mrk_defineClasses(mrk_orig, stimDef);
    mrk.orig = mrk_orig;
    mnt = mnt_setElectrodePositions(cnt.clab);
    % mnt= mnt_setGrid(mnt, 'M+EOG+EMG');
    
    % save in matlab format
    file_saving_name = fullfile(BTB.DataDir, 'Mat', ['OV/mvep/' folder '/' eegFiles{file}{1,1}]);
    file_saveMatlab(file_saving_name, cnt, mrk, mnt, 'Vars','hdr');
end

end