BTB_memo= BTB;
BTB.RawDir= fullfile(BTB.DataDir, 'demoRaw');
BTB.MatDir= fullfile(BTB.DataDir, 'demoMat');

% add more to the list if you want to do it in a row
subdir_list= {'VPkg_08_08_07'};
% you could have more files also
basename_list= {'calibration_motorimagery', ...
                'feedback_motorimagery'};

% definition of classes based on markers 
stimDef= {1, 2, 3;
          'left','right', 'foot'};


% load raw files (with filtering), define classes and montage,
% and save in matlab format
for k= 1:length(subdir_list);
 for ib= 1:length(basename_list),
  subdir= subdir_list{k};
  sbj= subdir(1:find(subdir=='_',1,'first')-1);
  file= fullfile(subdir, [basename_list{ib} sbj]);
  fprintf('converting %s\n', file)
  
  [cnt, mrk_orig, hdr] = file_readBV(file);
  
  % create mrk and mnt
  mrk= mrk_defineClasses(mrk_orig, stimDef);
  mrk.orig= mrk_orig;
  mnt= mnt_setElectrodePositions(cnt.clab);
  mnt= mnt_setGrid(mnt, 'M+EOG+EMG');
  
  % save in matlab format
  file_saveMatlab(file, cnt, mrk, mnt, 'Vars','hdr');
 end
end

BTB= BTB_memo;
