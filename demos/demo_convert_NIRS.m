% This is a demo for the BBCI toolbox that demonstrates preprocessing of
% NIRS data.

%February 2014 by Jan Mehnert (jan@mehnert.org)

% temporarily redefine BTB folders
BTBmemo= BTB;
BTB.RawDir= fullfile(BTB.DataDir, 'demoRaw');
BTB.MatDir= fullfile(BTB.DataDir, 'demoMat');

%% convert NIRx-system data to Matlab format

% define the positions of sources and detectors
% here we use the position of the 5-5-EEG electrode system as defined in Oostenveld R, Praastra P (2001): The five percent electrode system for high-resolution
% EEG and ERP measurements. Clinical Neurophysiology 112 (2001) 713-719
sources= {'Pz','C3','C1','FCz','C2','C4','F1','F2'};
detectors= {'POz','CPP1h','CPP2h','CCP3h','CCP4h','FCC5h','FCC3h','FCC1h','FCC2h','FCC4h','FCC6h','F3','AF1','Fz','AF2','F4'};

% filename of the raw NIRx data
filename= fullfile('VPean_10_07_26', 'NIRS', 'real_movementVPean');

%read the raw data into the new structure, calculate Beer-Lambert
[cnt, mrk, mnt, hdr]= ... 
    file_readNIRx(filename, 'LB',1, 'Source',sources, 'Detector',detectors);

% band-pass filter
lp_freq= [1/128 .4];
[b,a]= butter(3, lp_freq/cnt.fs*2);
cnt= proc_filtfilt(cnt, b, a);
% Here we use an acausal filter to avoid phase shifts in the time courses.
% However, this kind of filtering is not possible in online processing.

mrk= mrk_defineClasses(mrk, {1, 2; 'left', 'right'});

grd= sprintf(['C3FCC5h,C3FCC3h,C1FCC3h,C1FCC1h,C2FCC2h,C2FCC4h,C4FCC4h,C4FCC6h\n'...
              'scale,C3CCP3h,C1CCP3h,_,_,C2CCP4h,C4CCP4h,legend']);
mnt= mnt_setGrid(mnt, grd);

%save file in BBCI Matlab format
file_saveNIRSMatlab(filename, cnt, mrk, mnt);

%restore original BTB
BTB= BTBmemo;
