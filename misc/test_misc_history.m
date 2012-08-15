addpath /data/git/public/misc/
addpath /data/git/public/processing/

% Beispiel struct
dat=struct();
dat.x=randn(100,3);
dat.fs = 100;
dat.clab = {'Fz' 'Pz' 'Oz'};



dat2 = proc_linearDerivation(dat,eye(3),'labels','');
dat2= proc_filt(dat2,[.3 .3 .3],1);
dat2 = proc_wavelets(dat2,'freq',1:.2:20,'Mother','morlet');
dat2 = proc_logarithm(dat2);
dat2 = proc_normalize(dat2);


%% Apply history to new struct
datx=struct();
datx.x=randn(200,3);
datx.fs = 100;
datx.clab = {'Oz' 'Az' 'Ez'};

datx = misc_applyHistory(datx,dat2.history);

