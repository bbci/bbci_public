
function score = score_eigenvalues(~,~,D)
%SCORE_EIGENVALUES - Eigenvalues as score

score = 2*(diag(D)-.5);
score = score(:);

