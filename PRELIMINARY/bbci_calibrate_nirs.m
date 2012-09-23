function [bbci,data]=bbci_calibrate_nirs(bbci,data)

nirs_ival=[4000 8000];
opt.model=@train_RLDAshrink;


% make epochs:
epo=proc_segmentation(data.cnt,data.mrk,[-2000 10000]);

epo=proc_baseline(epo,[-2000 2000]);

% epo_hbo=epo;
% epo_hbo.x=epo_hbo.x(:,1:24,:);
% epo_hbr=epo;
% epo_hbr.x=epo_hbr.x(:,25:end,:);
% fv=proc_selectIval(epo_hbr,nirs_ival);

fv= proc_selectIval(epo,nirs_ival);
fv= proc_meanAcrossTime(fv);
bbci.signal.proc={};
bbci.signal.clab = data.cnt.clab;

bbci.feature.ival =[-2000 0];
bbci.feature.fcn = {@proc_meanAcrossTime};

bbci.classifier.C=trainClassifier(fv,opt.model);


[loss,loss_std]=xvalidation(fv,opt.model,'progress_bar',0,'verbosity',0);
disp(sprintf('xvalidation yields a loss of %2.1f +/- %2.1f %%',100*loss,100*loss_std))

data.result.classes=epo.className;

disp(sprintf('classifier trained'))
