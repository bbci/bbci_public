function OV_BBCI_convert_to_mat(folder)
%OV_BBCI_CONVERT_TO_MAT - convert vhdr files recorded using OpenVibe
% to BBCI mat format
%
%Synopsis:
% OV_BBCI_convert_to_mat(folder)
%
%
%Arguments:
% folder -   folder name containing .vhdr files
%
%Returns:
% creates folder and saves the converted
% .mat files in BTB.MatDir/Mat/OV/folder
% Note:
% Requires running ov2vhdr scenario in OpenVibe at first in order to convert
% .ov files to vhdr format
%
% Okba Bekhelifi, LARESI, USTO-MB <okba.bekhelifi@univ-usto.dz>
% 02-2017

global BTB

if exist('BTB','var') == 0
    if exist('init_bbci','file') == 2 
%         the author's own script to run BBCI
        init_bbci;
    else
        error('run BBCI with startup_bbci_toolbox first');
    end
end


foldertmp = fullfile(BTB.DataDir, 'Raw', ['OV\' folder]);
files = dir([foldertmp '\*.vhdr']);
eegFiles = {files.name};
eegFiles = cellfun(@(s) strsplit(s, '.vhdr'), eegFiles, 'UniformOutput', false);

for file = 1:length(eegFiles)
    
    filepath = [foldertmp '/' eegFiles{file}{1,1}];
    [cnt, mrk_orig, hdr] = file_readBV(filepath);
    % OpenVibe's stimuli code: 
    % target, nontarget         
    if (isempty(cell2mat(strfind(mrk_orig.className,'S 11'))))
        stimDef = {33285,33286;'target', 'nontarget'};
    else
        % Pyff ERP feedback markers style
        % current definition hold 8 stimuli
        % change it to your number of stimuli    
        stimDef= {31:38, 11:18; 'target', 'nontarget'};
    end
    
    mrk = mrk_defineClasses(mrk_orig, stimDef);
    mrk.orig = mrk_orig;
    mnt = mnt_setElectrodePositions(cnt.clab);
    mnt = mnt_setGrid(mnt, 'XXL');
    
    % save in matlab format
    % default OpenVibe recorded files has date & time format containing
    % points, removing points from the file name before constructing
    % a new .mat filename
    str = eegFiles{file}{1,1};
    point_idx = strfind(str,'.');
    if ~isempty(point_idx)
        str(point_idx)=[];        
    end
    file_saving_name = fullfile(BTB.DataDir, 'Mat', ['OV\' folder '\' str]);
    file_saveMatlab(file_saving_name, cnt, mrk, mnt, 'Vars','hdr');
end

end