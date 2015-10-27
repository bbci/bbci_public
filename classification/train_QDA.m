function C= train_QDA(xTr, yTr, varargin)
%TRAIN_QDA - Quadratic Discriminant Analysis 
%
%Synopsis:
%   C = train_QDA(XTR, YTR)
%   C = train_QDA(XTR, YTR, PRIOR)
%
%Arguments:
% XTR: DOUBLE [NxM] - Data matrix, with N feature dimensions, and M
%                     training points/examples. 
% YTR: INT [CxM] - Class membership labels of points in X_TR. C by M matrix
%                  of training labels, with C representing the number of
%                  classes and M the number of training examples/points.
%                  Y_TR(i,j)==1 if the point j belongs to class i.
% PRIOR: DOUBLE - (default ones(nClasses, 1)/nClasses): Empirical class
%                 priors
%
%Returns:
%   C: STRUCT - Trained classifier structure, with the hyperplane given by
%               fields C.w, C.b and C.sq
%
%See also:
%   APPLY_QDA


if size(yTr,1)==1,
  nClasses= 2;
  clInd{1}= find(yTr==-1);
  clInd{2}= find(yTr==1);
  N= [length(clInd{1}) length(clInd{2})];
else
  nClasses= size(yTr,1);
  clInd= cell(nClasses,1);
  N= zeros(nClasses, 1);
  for ci= 1:nClasses,
    clInd{ci}= find(yTr(ci,:));
    N(ci)= length(clInd{ci});
  end
end

if nargin==2
  priorP= ones(nClasses,1)/nClasses;
else
  priorP= varargin{1};
end
if isequal(priorP, '*')
  priorP = N/sum(N);
end
 
d= size(xTr,1);
C.w= zeros(d, nClasses);
C.b= zeros(1, nClasses);
C.sq= zeros(d, d, nClasses);
for ci= 1:nClasses,
  cli= clInd{ci};
  C.w(:,ci)= mean(xTr(:,cli), 2);
  yc= xTr(:,cli) - C.w(:,ci)*ones(1,N(ci));
  Sq= yc*yc';
  C.sq(:,:,ci)= Sq / (N(ci)-1);
end
C.b= zeros(1, nClasses);
for ci= 1:nClasses,
  S= C.sq(:,:,ci);
  S= pinv(S);
  C.sq(:,:,ci)= -0.5*S;
  C.b(ci)=  -0.5*C.w(:,ci)' * S*C.w(:,ci) + ...
            0.5*log(max([det(S),realmin])) + log(priorP(ci));
  C.w(:,ci)= S*C.w(:,ci);
end
C.b=C.b';

if nClasses==2,
  sq(:,:)= C.sq(:,:,2) - C.sq(:,:,1);
  C.sq= sq;
  C.w= C.w(:,2)-C.w(:,1);
  C.b= C.b(2) - C.b(1);
end
