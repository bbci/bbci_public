
function score = score_auc(dat,W,~)
%SCORE_AUC - AUC values of projected components as score

fv = proc_linearDerivation(dat, W);
fv = proc_variance(fv);
fv = proc_aucValues(fv);
score = -fv.x;

score = score(:);

