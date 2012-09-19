function [C,maxVar] = train_SWLDAmatlab(xTr, yTr, varargin)
% TRAIN_SWLDA - Train stepwise LDA using the Matlab function stepwisefit
%
% Synopsis:
%   C = TRAIN_SWLDAmatlab(XTR, YTR)
%   C = TRAIN_SWLDAmatlab(XTR, YTR, OPTS)
%
% Arguments:
%   XTR: DOUBLE [MxN] - Data matrix, with N feature dimensions, and M training points/examples. 
%   YTR: INT [CxM] - Class membership labels of points in X_TR. C by M matrix of training
%                     labels, with C representing the number of classes and M the number of training examples/points.
%                     Y_TR(i,j)==1 if the point j belongs to class i.
%   OPT: PROPLIST - Structure or property/value list of optional
%                   properties:
%    'MaxVar' - INT (default M): Maximum number of selected variables by stepwise LDA.
%    'PEntry' - DOUBLE (default 0.1): Threshold for p-value of a variable to enter regression
%    'PRemoval' - DOUBLE (default: 0.15): Variables are eliminated if p-value of partial f-test exceeds PRemoval
%
% Returns:
%   C: STRUCT - Trained classifier structure, with the hyperplane given by
%               fields C.w and C.b.
%
% Description:
%   TRAIN_SWLDA trains a stepwise LDA classifier on data XTR with class
%   labels given in YTR. The stepwise procedure stops when there 
%   are no more variables falling below the critical p-value of PEntry.
%   It can be limited by MaxVar, the maximum number of variables
%   that should be selected. The critical p-value for removal is
%   set to PRemoval.
%
%   References: N.R. Draper, H. Smith, Applied Regression Analysis, 
%   2nd Edition, John Wiley and Sons, 1981. This function implements
%   the algorithm given in chapter 'Computional Method for Stepwise 
%   Regression' of the first edition (1966).
%
% Examples:
%   train_SWLDAmatlab(X, labels)
%   train_SWLDAmatlab(X, labels, 'MaxVar',12,'PEntry',0.1,'PRemoval',0.15)
%   
%   
% See also:
%   APPLY_SEPARATINGHYPERPLANE, TRAIN_LDA, TRAIN_SWLDA
%

% 12-09-2012: revised to fit with new naming standards and automatic
% opt-type checking (Michael Tangermann)
% created true propertylist handling

props= {'MaxVar'      size(yTr,2) 'INT'
        'PEntry'      0.1         'DOUBLE'
        'PRemoval'    0.15        'DOUBLE'
       };

if nargin==0,
  C= opt_catProps(props); 
  return
end

opt= opt_proplistToStruct(varargin{:});
[opt, isdefault]= opt_setDefaults(opt, props, 1);



maxVar = opt.MaxVar;
pEntry = opt.PEntry;
pRemoval = opt.PRemoval;

if maxVar<1 | maxVar>size(yTr,2),
  error(['limiting parameter of setpwise procedure MAXVAR must be between 1 and ' num2str(size(yTr,2))]);
end

[b, se, pval, inmodel, stats]= ...
    stepwisefit(xTr', ([-1 1]*yTr)', 'penter',pEntry, 'premove',pRemoval, ...
                'maxiter',maxVar, 'display','off');
C.w= zeros(size(b));
C.w(inmodel)= b(inmodel);
%C.b= stats.intercept;
idx1= find(yTr(1,:));
idx2= find(yTr(2,:));
C.b = -C.w'*(mean(xTr(:,idx2),2)+mean(xTr(:,idx1),2))/2;
