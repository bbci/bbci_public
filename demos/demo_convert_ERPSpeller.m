BTB_memo= BTB;
BTB.RawDir= fullfile(BTB.DataDir, 'demoRaw');
BTB.MatDir= fullfile(BTB.DataDir, 'demoMat');

% add more to the list if you want to do it in a row
subdir_list= {'VPiac_10_10_13'};
% you could have more files also
basename_list= {'calibration_CenterSpellerMVEP_'};

Fs = 100; % new sampling rate
% definition of classes based on markers 
stimDef= {[31:46], [11:26];
          'target','nontarget'};


% load raw files (with filtering), define classes and montage,
% and save in matlab format
for k= 1:length(subdir_list);
 for ib= 1:length(basename_list),
  subdir= subdir_list{k};
  sbj= subdir(1:find(subdir=='_',1,'first')-1);
  file= fullfile(subdir, [basename_list{ib} sbj]);
  fprintf('converting %s\n', file)
  % header of the raw EEG files
  hdr = file_readBVheader(file);
  
  % low-pass filter
  Wps = [42 49]/hdr.fs*2;
  [n, Ws] = cheb2ord(Wps(1), Wps(2), 3, 40);
  [filt.b, filt.a]= cheby2(n, 50, Ws);
  % load raw data, downsampling is done while loading (after filtering)
  [cnt, mrk_orig] = file_readBV(file, 'Fs',Fs, 'Filt',filt);

  % Re-referencing to linked-mastoids
  %   (data was referenced to A2 during acquisition)
  A = eye(length(cnt.clab));
  iref2 = util_chanind(cnt.clab, 'A1');
  A(iref2,:) = -0.5;
  A(:,iref2) = [];
  cnt = proc_linearDerivation(cnt, A);
  
  % create mrk and mnt
  mrk= mrk_defineClasses(mrk_orig, stimDef);
  mrk.orig= mrk_orig;
  mnt= mnt_setElectrodePositions(cnt.clab);
  mnt= mnt_setGrid(mnt, 'M+EOG');
  
  % save in matlab format
  file_saveMatlab(file, cnt, mrk, mnt, 'Vars','hdr');
 end
end

BTB= BTB_memo;
