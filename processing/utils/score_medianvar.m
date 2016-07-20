function score = score_medianvar(dat,W,~)
%SCORE_MEDIANVAR - Median variance of projected components as score

nChans = size(dat.x,2);

if size(W,2)<nChans
    nChans=size(W,2);
end

fv = proc_linearDerivation(dat,W);
fv = proc_variance(fv);
score = zeros(nChans,1);
for kk = 1:nChans
    v1 = median(fv.x(1,kk,logical(fv.y(1,:))),3);
    v2 = median(fv.x(1,kk,logical(fv.y(2,:))),3);
    score(kk) = v2/(v1+v2);
end

score = 2*(score-.5);

score = score(:);

