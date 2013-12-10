files = {
    {'VPibq_10_09_24', 'calibration_CenterSpellerMVEP_VPibq'}
%     {'VPiac_10_10_13', 'calibration_CenterSpellerMVEP_VPiac'}
%     {'VPibs_10_10_20', 'calibration_CenterSpellerMVEP_VPibs'}
%     {'VPibt_10_10_21', 'calibration_CenterSpellerMVEP_VPibt'}
%     {'VPfat_10_10_27', 'calibration_CenterSpellerMVEP_VPfat'}
%     {'VPibu_10_10_28', 'calibration_CenterSpellerMVEP_VPibu'}
%     {'VPibv_10_11_02', 'calibration_CenterSpellerMVEP_VPibv'}
%     {'VPibw_10_11_04', 'calibration_CenterSpellerMVEP_VPibw'}
%     {'VPibx_10_11_10', 'calibration_CenterSpellerMVEP_VPibx'}
%     {'VPiby_10_11_12', 'calibration_CenterSpellerMVEP_VPiby'}
%     {'VPice_10_12_17', 'calibration_CenterSpellerMVEP_VPice'}
%     {'VPgdf_11_06_09', 'calibration_CenterSpellerMVEP_VPgdf'}
%     {'VPicv_11_06_10', 'calibration_CenterSpellerMVEP_VPicv'}
%     {'VPgdg_11_06_22', 'calibration_CenterSpellerMVEP_VPgdg'}
%     {'VPibe_11_06_16', 'calibration_CenterSpellerMVEP_VPibe'}
%     {'VPiba_11_06_23', 'calibration_CenterSpellerMVEP_VPiba'}
    };

Fs = 100; % new sampling rate
stimDef= {[31:46], [11:26];
          'target','nontarget'};
      
% global BBCI
% BBCI.RawDir = '/home/bbci/data/bbciRaw/';
% BBCI.MatDir = '/home/bbci/data/bbciMat/';


%% load raw files and save in matlab format

for k= 1:length(files);
    
  fprintf('converting %s\n', files{k}{2})
  % header of the raw EEG files
  raw_file = fullfile(files{k}{1},files{k}{2});
  hdr = file_readBVheader(raw_file);
  
  % low-pass filter
  Wps = [42 49]/hdr.fs*2;
  [n, Ws] = cheb2ord(Wps(1), Wps(2), 3, 40);
  [filt.b, filt.a]= cheby2(n, 50, Ws);
  % load raw data, downsampling is done while loading
  [cnt, mrk_orig] = file_readBV(raw_file, 'Fs',Fs, 'Filt',filt);

  % Re-referencing to linked-mastoids
  A = eye(length(cnt.clab));
  iA1 = util_chanind(cnt.clab,'A1');
  if isempty(iA1)
    iA1 = util_chanind(cnt.clab,'A2');
  end
  A(iA1,:) = -0.5;
  A(:,iA1) = [];
  cnt = proc_linearDerivation(cnt, A);
  
  % create mrk and mnt, and the new filename
  mrk = mrk_defineClasses(mrk_orig, stimDef);
  mnt = mnt_setElectrodePositions(cnt.clab);
  mat_file_name = fullfile(sprintf('demo_%s', files{k}{1}), files{k}{2});
  
  % save in matlab format
  fprintf('saving %s\n', mat_file_name)
  file_saveMatlab(mat_file_name, cnt, mrk, mnt);
  
end