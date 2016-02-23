
function score = score_eigenvalues(~,~,D)
%SCORE_EIGENVALUES - Eigenvalues as score

score = diag(D);
score = score(:);

