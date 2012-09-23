files = {
    {'VPibv_10_11_02', 'calibration_CenterSpellerMVEP_VPibv'}
    };

Fs = 100; % new sampling rate
stimDef= {[31:46], [11:26];
          'target','nontarget'};

%% load raw files and save in matlab format

for k=1:length(files);
    % header of the raw EEG files
    raw_file = fullfile(files{k}{1},files{k}{2});
    hdr= file_readBVheader(raw_file);
    
    % low-pass filter
    Wps = [42 49]/hdr.fs*2;
    [n, Ws] = cheb2ord(Wps(1), Wps(2), 3, 40);
    [filt.b, filt.a]= cheby2(n, 50, Ws);
    % load raw data, downsampling is done while loading
    [cnt, mrk_orig] = file_readBV(raw_file, 'Fs',Fs, 'Filt',filt);
    
    % create mrk and mnt, and the new filename
    mrk = mrk_defineClasses(mrk_orig, stimDef);
    mnt = mnt_setElectrodePositions(cnt.clab);
    mat_file_name = sprintf('demo_%s', files{k}{1});
    
    % save in matlab format
    fprintf('saving %s\n', mat_file_name)
    file_saveMatlab(mat_file_name, cnt, mrk, mnt);
    
end