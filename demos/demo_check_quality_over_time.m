eeg_file= fullfile(BTB.DataDir, 'demoMat', 'VPiac_10_10_13', ...
                   'calibration_CenterSpellerMVEP_VPiac');

% Load data
try
  [cnt, mrk, mnt] = file_loadMatlab(eeg_file);
catch
  error('You need to run ''demo_convert_ERPSpeller'' first');
end


nBlocks= 6;

% define 'nBlocks' intervals ranging from the first to the last marker:
inter = linspace( mrk.time(1), mrk.time(end), nBlocks+1 );
blk = struct( 'ival', [inter(1:end-1)' inter(2:end)'] );

% define marker structure: one marker every second
mrkblk = mrk_evenlyInBlocks( blk, 1000 );
% assign class labels for each marker corresponding to the block
mrkblk.y = util_classind2labels( mrkblk.event.blkno );
mrkblk.className= str_cprintf('block %d', 1:6);

% calculate spectra (average within the defined blocks)
spec = proc_segmentation( cnt, mrkblk, [0 1000] );
spec = proc_spectrum( spec, [5 40], kaiser(cnt.fs,2) );

% visualize the block-wise spectra
fig_set(1);
cmap= cmap_hsvFade(nBlocks, [0 5/6], 1, 1);
grid_plot( spec, mnt , defopt_spec, 'ColorOrder',cmap );

% increasing noise level can be observed, e.g. in channels C6 and T8
