basename= 'CenterSpellerMVEP_';
subdir_list= {'VPibv_10_11_02'};
%subdir_list= {'VPibq_10_09_24'
%              'VPiac_10_10_13'
%              'VPibs_10_10_20'
%              'VPibt_10_10_21'
%              'VPfat_10_10_27'
%              'VPibu_10_10_28'
%              'VPibv_10_11_02'
%              'VPibw_10_11_04'
%              'VPibx_10_11_10'
%              'VPiby_10_11_12'
%              'VPice_10_12_17'
%              'VPgdf_11_06_09'
%              'VPicv_11_06_10'
%              'VPgdg_11_06_22'
%              'VPibe_11_06_16'
%              'VPiba_11_06_23'
%             }; 

Fs = 100; % new sampling rate
stimDef= {[31:46], [11:26];
          'target','nontarget'};


%% load raw files and save in matlab format

for k= 1:length(subdir_list);
  subdir= subdir_list{k};
  sbj= subdir(1:find(subdir=='_',1,'first')-1);
  raw_file= fullfile(subdir, ['*_' basename sbj]);
  fprintf('converting %s\n', raw_file)
  % header of the raw EEG files
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
  mat_file_name = fullfile(subdir, ['demo_' basename, sbj]);
  
  % save in matlab format
  fprintf('saving %s\n', mat_file_name)
  file_saveMatlab(mat_file_name, cnt, mrk, mnt);
  
end