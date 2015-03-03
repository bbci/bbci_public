function [mushr, lambda, label, problem] = clsutil_meanMTS(data, varargin)
% clsutil_meanMTS performs shrinkage of the mean. 
% 
%
% Synopsis:
%
% Arguments:
%       data (struct):           
%           X{1} (TxD): matrix with data time series
%           X{2-N_sim+1} (T_sim x D): set of matrices of time series from similar data sets
%
%
%	Optional Inputs:
%           convex (bool): solve for a convex combination of matrices -
%                           default 1
%           conservative (bool): the additional data sets do not receive
%                                   weights larger than their ratio of data
%                                   points - default 1
%           variablewise (bool): each dimension is shrunk separately -
%                                default 0
%
%
% Outputs:
%       mushr (DxD): estimated shrinkage mean
%       lambda (#targets x 1): MSE-optimal weights of the linear combination
%       label ( #targets cell array): labels corresponding to the lambdas
%       problem  ( struct ): the optimization problem solved by quadprog in
%                              multishrink_optimization
%
% Description:
%  - clsutil_meanMTS allows an arbitrary or convex linear combination of mean estimators
%  - lambdas are in general restricted to [0, 1]
%  - prevent overshrinkage to additional data.
%  - entry-wise sotm for vectorial data
%  - dependent on optimization toolbox (quadprog)
%
% 22.11.2013:
% - generated from multishrink and multishrink_optimization
% - variablewise shrinkage implemented
%
% 26.02.2014: updated naming corresponding to BBCI toolbox (JohannesHoehne)
%
% Copyright (C) 2011-13, Daniel Bartz
% TU Berlin
% Fakultaet IV - Informatik
% Fachgruppe fuer Maschinelles Lernen
%

props= {	'variablewise'      0    'BOOL'
            'convex'            1    'BOOL'
            'conservative'      1    'BOOL'   };

if nargin==0,
  mushr= props;
  return
end
opt= opt_proplistToStruct(varargin{:});
[opt, isdefault]= opt_setDefaults(opt, props);
opt_checkProplist(opt, props);



% added by Johannes to prevent the no-subclass data problem
if size(data.X{1},1)<2
    myX = data.X{1};
    for idat = 2:length(data.X)
        myX = [myX;data.X{idat}];
        sz(idat) = size(data.X{idat},1);
    end
    mushr = mean(myX)';
    lambda = sz(2:end) / sum(sz);
    lambda = lambda';
    return
end
        
        
if opt.variablewise
    % disp('running variable-wise sotm')
    opt.variablewise = false;
    n1 = length(data.X);
    X0 = data.X{1};
    [N0, D] = size(  X0  );
    mushr = zeros(D,1);
    lambda = zeros(D,1);
    
    for i=1:D
        data1D = {};
        for j=1:n1
            data1D.X{j} = data.X{j}(:,i);
        end
        [mushr(i), lambdas1D] = sotm(data1D,opt);
        lambda( i, 1:length(lambdas1D) ) = lambdas1D;
    end
    
    return
end


% calculate the statistics!
n1 = length(data.X);
X0 = data.X{1};
[N0, D] = size(  X0  );
    

% shrinkage of the mean!
% S := sample mean
stat.S = mean(X0)'; 

Vmat = var(X0)/N0;

stat.SV = sum( Vmat );


% 2. calculate the needed statistics from the "similar data sets"
if n1>1
    for i=1:n1-1
        % else if sotm from multishrink
        stat.Ct(:,i) = mean(data.X{i+1},1);
        stat.covCtS(i) = 0;
        
        label{i} = ['old data set ',num2str(i)];
    end
end

% shall the similar data sets be employed conservatively?
% CHECK THIS!
if opt.conservative > 0
    opt.conservative = double( opt.conservative );
    if n1>1
        for i=1:n1-1
            opt.conservative(i,1) = i;
            opt.conservative(i,2) = size(  data.X{1},1  )/size(  data.X{i+1},1  );
        end
    end
end
    
    
% calcuate the similar data sets covariance-variances in order to check if
% E[ (u-t)^2 ] is estimated badly...
% INACTIVE -- CHECK IF THIS MIGHT HELP FOR THE SOTM  PROBLEM!
opt.lowBoundAii = false;
if opt.lowBoundAii
    if n1>1
        for i=1:n1-1
            X1 = data.X{i+1};
            [N1, D] = size(  X1  );

                SumV1ij = 0;
                for ii= 1:D-1,
                  for jj= ii+1:D,
                    V0 = N1/(N1-1)^2 * var(X1(:,ii).*X1(:,jj));
                    SumV1ij = SumV1ij + V0;
                  end
                end
                SumV1ii = 0;
                for ii= 1:D,
                  V0 = N1/(N1-1)^2 * var(X1(:,ii).*X1(:,ii));
                  SumV1ii = SumV1ii + V0;
                end

            opt.lowBoundAii(i) = SumV1ii + SumV1ij + stat.SV;
        end
    end
end
    
%
n = n1-1;
if isfield(data,'targets')
    % would it make sense to shrink the mean to zero or the other value?
    % maybe not much...
    % TBD!
end


% call the multishrink_optimization routine
[lambda, problem] = sotm_optimization(stat.S,stat.SV, stat.Ct, stat.covCtS,...
                        'convex', opt.convex,...
                        'conservative',opt.conservative,...
                        'lowBoundAii',opt.lowBoundAii...
                        );

% calculate the shrinkage mean
mushr = (   1-sum(lambda)   )*stat.S;
if n > 0;
    for i=1:n
        mushr = mushr + lambda(i)*stat.Ct(:,i);
    end
end

end





function c = strf2(a,b)
    c = any( strfind(a,b)  );
end





function [lambda, problem] = sotm_optimization(C0, varC0, C, covCC0, varargin)
% SUBFUNCTION of clsutil_meanMTS
% sotm_optimization performs shrinkage towards multiple target means by solving a
% quadratic program.
%
% Features
%  - the function allows an arbitrary or convex linear combination of
%    covariance estimators.
%  - lambdas are restricted to [0, 1]
%
%
% Here, the 
%
%   Inputs:
%       C0 (DxD): sample mean
%       C (DxDxN): set of shrinkage mean
%       varC0 (1): est. variance of the sample covariance estimator
%       covCC0 (Nx1): est. covariance betweeen sample mean and shrinkage targets
%
%	Variable Inputs:
%           convex (bool): solve for a convex combination of matrices
%           trace (bool): solve under the constraint of trace
%                               conservation
%
%
%   Output:
%       lambda (Nx1): MSE-optimal weights of the linear combination
%
%
% 22.11.2013:
%   - re-write tidy sotm version from multishrink_optimization
%

props= {    'trace'             0    'BOOL'
            'convex'            0    'BOOL'
            'conservative'      0    'BOOL|DOUBLE[- -]'   %not very well implemented, since "conservative" may change from a bool-flag to a matrix within clsutil_meanMTS
            'lowBoundAii'       0    'BOOL'
            'normalized'        0    'BOOL'
            'con_crossbias'     0    'BOOL'
            };
        
opt= opt_proplistToStruct(varargin{:});
[opt, isdefault]= opt_setDefaults(opt, props);
opt_checkProplist(opt, props);


%func start
% obtain number of shrinkage targets
N = size(C,2);

        
% if an arbitrary linear combination is allowed, introduce an empty dummy mean
if ~opt.convex
    % set an empty dummy matrix
    N = N+1;
    covCC0(N) = 0;
    
    C(:,N) = 0;
end
        
% Define the matrices which build up the quadratic program
C = C - repmat(C0,[1 N]);

H = zeros(N);
for i=1:N
    for j=1:i
        H(i,j) = sum(     C(:,i).*C(:,j)  );
    end
end

% INACTIVE
if opt.lowBoundAii(1) > 0
    for i=1:length(opt.lowBoundAii)
        H(i,i) = max( opt.lowBoundAii(i), H(i,i) );
    end
end

problem.H = 2* (   H + tril(H,-1)'   );
problem.f = 2*(   covCC0 - varC0   );
problem.Aineq = ones(1,N);
problem.bineq = 1;
problem.Aeq = [];
problem.beq = [];
problem.lb = zeros(N,1);

% if opt.con_crossbias
%     problem.H( problem.H < 0 ) = 0;
% end


if strcmp(version,'7.4.0.287 (R2007a)')
    problem.x0 = zeros(size(problem.f));
end

% if an arbitrary linear combination is allowed, un-bound the dummy lambda
if ~opt.convex
    problem.lb(end) = -inf;
end

problem.ub = [];
% problem.x0 = ones(N,1)/(N+1);
problem.solver = 'quadprog';
problem.options = optimset('Display','off');

% if similar data sets shall have limited importance
if opt.conservative(1) > 0
    % what exaktly does the conservative flag?
    % - no other mean is allowed to get a weighting larger than the
    %   original on relative to the sample size
    % - for each mean there has to be one inequality constraint:
    %   { 1 - sum(lambdas) } / size(data) >= lambda_i / size( target_i )
    for i=1:size(opt.conservative,1)
        Aineq = ones(1,N);
        Aineq(i) = 1 + opt.conservative(i,2);
        problem.Aineq = [problem.Aineq; Aineq];
        problem.bineq = [problem.bineq; 1];
    end
end


% solve the quadratic program
warning off optim:quadprog:SwitchToMedScale
lambda = quadprog( problem );


% check if all the weights are within the intervall [0, 1]
% disp('TO DO: weight restriction ') - done by constraining...

end
