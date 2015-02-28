function C = train_RSLDAshrink(xTr, yTr, sublab, varargin)
% TRAIN_RSLDASHRINK - Relevance Subclass LDA with mean shrinkage to subclasses and automatic covariance shrinkage
%
%Synopsis:
%   C = train_RLSDAshrink(XTR, YTR, SUBLABELS)
%   C = train_RLSDAshrink(XTR, YTR, SUBLABELS, OPTS)
%
%Arguments:
%   XTR: DOUBLE [NxM] - Data matrix, with N feature dimensions, and M training points/examples. 
%   YTR: INT [CxM] - Class membership labels of points in X_TR. C by M matrix of training
%                     labels, with C representing the number of classes and M the number of training examples/points.
%                     Y_TR(i,j)==1 if the point j belongs to class i.
%   SUBLABELS[Mx1] - Subclass membership for each data point
%   OPT: PROPLIST - Structure or property/value list of optional
%                   properties. 
%     'Whitening' - BOOL (default 1): If true, mean shrinkage is performed
%       on whitened data. This is important for ERP data, as it has a
%       highly skewed eigenspectrum and the mean shrinkage is dominated by
%       directions of high variance.
%     'ReturnRegularizationProfile' - BOOL (default 1): If true, returns regularization
%       profile as matrix MxM for both classes, with M being the number of
%       unique subclasses. 
%
%Returns: 
%   C: STRUCT - Trained classifier structure, with the subclassifier
%     hyperplanes given by fields C.subC{k}.w and C.subC{k}.b for each
%     subclass k
% 
% C includes the fields:
%    'sublab_unique' :      unique subclass labels
%    'pattern' :            pattern (i.e. mu2-mu1) of each subclassifier
%    'subC' :               LDA classifiers (w and b) for each subclass
%    'regularization_list': list of regularization weights for each class
%       and subclass, stacked for both classes 
%    'regularization_profile' : (optional) regularization profile as matrix
%
%Description:
%   TRAIN_RLSDA trains a Relevance Subclass LDA classifier on data X with 
%   class labels given in LABELS and Subclass labels given in SUBLABELS. 
%   The mean shrinkage parameter is selected by sotm and the covariance
%   shrinkage parameter is selected by the function clsutil_shrinkage.
%
%
%Example 1:
%%perform standard ERP analysis (loads data, subsampling and divide into epochs)
% demo_analysis_ERPs
% 
% 
%%only the last digit codes for the stimulus identity
% subclass_lab = mod(epo.event.desc, 10);
% 
%%extract features from the epochs by subsampling
% ivals = [140:30:260 300:50:600; 170:30:300 350:50:650]';
%%create features
% fv = proc_flaten(proc_jumpingMeans(epo, ivals));
%%train RSLDA
% C = train_RSLDAshrink(fv.x, fv.y, subclass_lab);
% 
%%Example 2: compare RSLDAshrink with LDAshrink
% nfolds = 4;
% [divTr, divTe] = sample_KFold(epo.y, nfolds);
% loss_list_RSLDA = nan(1, nfolds);loss_list_RLDA = loss_list_RSLDA;
% for kk = 1:nfolds
%     %generate training and test features
%     fvTr = proc_flaten(proc_jumpingMeans(proc_selectEpochs(epo, divTr{1}{kk}), ivals));
%     fvTe = proc_flaten(proc_jumpingMeans(proc_selectEpochs(epo, divTe{1}{kk}), ivals));    
%     %train cls on traing data
%     C_RSLDA = train_RSLDAshrink(fvTr.x, fvTr.y, subclass_lab(divTr{1}{kk}));
%     C_LDA = train_RLDAshrink(fvTr.x, fvTr.y);
%     %apply RSLDA on the test data
%     out_RSLDA = apply_RSLDAshrink(C_RSLDA, fvTe.x, subclass_lab(divTe{1}{kk}));
%     out_RLDA = apply_separatingHyperplane(C_LDA , fvTe.x);
%     
%     loss_list_RSLDA(kk) = loss_rocArea(fvTe.y,out_RSLDA);
%     loss_list_RLDA(kk) = loss_rocArea(fvTe.y,out_RLDA);
% end
%%compare loss for each fold
% loss_list_RSLDA - loss_list_RLDA
%%plot regularization profile for the last fold
% figure, imagesc(C_RSLDA.regularization_profile{2})
%   
%See also:
%   APPLY_SEPARATINGHYPERPLANE, CLSUTIL_SHRINKAGE, TRAIN_RLDA
%   TRAIN_LDA

% 02-2015 Johannes Hoehne

props= {'Whitening'        1                             'BOOL'
        'ReturnRegularizationProfile'  1                 'BOOL'
       };
   
% get props list of the subfunction
props_shrinkage= clsutil_meanMTS;

if nargin==0,
  C= opt_catProps(props, props_shrinkage); 
  return
end

opt= opt_proplistToStruct(varargin{:});
[opt, isdefault]= opt_setDefaults(opt, props);
opt_checkProplist(opt, props, props_shrinkage);

% preprocessing of input
if size(yTr,1)==1, yTr= [yTr<0; yTr>0]; end
yTr = logical(yTr);
if size(sublab,2)==1 && size(sublab,1)>1
    sublab = sublab'; %sublab is expected to be a row-vector of  
end
C = {};

%start func
C.sublab_unique = unique(sublab);

% get meanfree X (without considereing subclass labels)
% compute Cov matrix
if opt.Whitening
    M1 = mean(xTr(:, yTr(1,:)),2);
    M2 = mean(xTr(:,yTr(2,:)),2);
    M = repmat(M1, 1, size(yTr,2));
    M(:, yTr(2,:)) = repmat(M2, 1, sum(yTr(2,:)));
    Xmeanfree_dum = xTr - M;
    globalCov = clsutil_shrinkage(Xmeanfree_dum);
    [ Eigvec, Eigval  ] = eig(globalCov);
    A_feat2white =  Eigvec * (Eigval^-.5) * Eigvec;
    A_white2feat = inv(A_feat2white); 
else %do not perform whitening 
%     --> this leads to a poor performance for data with a skewed eigen spectrum
    A_feat2white = eye(size(xTr,2));
    A_white2feat = eye(size(xTr,2));
end
Xwhite = A_feat2white' * xTr;    


kk = 0;
M = nan(size(xTr)); %saves the classwise-shrinked means
for my_sublab = C.sublab_unique
    kk = kk+1;
    
    %% estimate means
    % TARGETS aka: class 1
    shrink_dat = {}; %initialize shrindat container
    shrink_dat.X = {Xwhite(:,((sublab == my_sublab) & yTr(1,:)))' };
    
    %there might be sublabels without target stimuli -> skip them as sublabel
    sublab_missing = []; 
    for sublab_this = setdiff(C.sublab_unique, my_sublab)
        if sum((((sublab == sublab_this)) & yTr(1,:)))>0
            shrink_dat.X{end+1} = Xwhite(:,(((sublab == sublab_this)) & yTr(1,:)))';
        else
            sublab_missing(end+1) = sublab_this; %(only important for special cases)
        end
    end
    
    %PERFORM MULTI-TARGET SHINKAGE FOR CLASS 1
    % sublab=k & T   sublab~=k & T
    [M1est, gamma1] = clsutil_meanMTS(shrink_dat, 'convex', 1, 'variablewise', 0, 'conservative', 1);
    
    % (only important for special cases) deal with the arrangement of missing subclass labels 
    for xx = sublab_missing %put missing subclasses as zeros in gamma to maintain the correct size
        if xx>=length(gamma1)+1, gamma1 = [gamma1; 0]; %the last one was missing
        else  gamma1 = [gamma1(1:xx-1); 0; gamma1(xx:end)]; %another one was missing
        end
    end    
    
    % NON-TARGETS aka: class 2
    shrink_dat = {}; %initialize shrindat container
    shrink_dat.X = {Xwhite(:,((sublab == my_sublab) & yTr(2,:)))' };
        
    sublab_missing = []; %there might be sublabels without nontarget stimuli -> skip them as sublabel    
    for sublab_this = setdiff(C.sublab_unique, my_sublab) %for each unique subclass
        if sum((((sublab == sublab_this)) & yTr(2,:)))>0
            shrink_dat.X{end+1} = Xwhite(:,(((sublab == sublab_this)) & yTr(2,:)))';
        else sublab_missing(end+1) = sublab_this; % (only important for special cases)
        end            
    end
    
    
    %PERFORM MULTI-TARGET SHINKAGE FOR CLASS 2
    % sublab=k & NT   sublab~=k & NT
    [M2est, gamma2] = clsutil_meanMTS(shrink_dat, 'convex', 1, 'variablewise', 0, 'conservative', 1);
    
    % (only important for special cases) deal with the arrangement of missing subclass labels 
    for xx = sublab_missing %put missing subclasses as zeros in gamma to maintain the correct size
        if xx>=length(gamma2)+1, gamma2 = [gamma2; 0]; %the last one was missing
        else  gamma2 = [gamma2(1:xx-1); 0; gamma2(xx:end)]; %another one was missing
        end
    end   
        
    %transform the Means back into feature space
    M1est = A_white2feat' * M1est;
    M2est = A_white2feat' * M2est;
    
    % for each datapoint, save the dcorresponding subclass mean
    % --> build up Mean-template M with Target and NonTarget template 
    M(:, find(yTr(1,:) & sublab == my_sublab)) = repmat(M1est, 1, length(find(yTr(1,:) & sublab == my_sublab)));
    M(:, find(yTr(2,:) & sublab == my_sublab)) = repmat(M2est, 1, length(find(yTr(2,:) & sublab == my_sublab)));    
    
    %save the mean estimators as we need them later to compute the cls
    list_M1{kk} = M1est;
    list_M2{kk} = M2est;
    
    C.regularization_list(:,kk) =  [gamma1', gamma2']';
end


%% estimate Cov with optimized means
Xmeanfree = xTr - M;
Cest = clsutil_shrinkage(Xmeanfree);
C_invcov = pinv(Cest);

%% finalize cls
kk = 0;
for my_sublab = C.sublab_unique
    kk = kk+1;
    % get the Target and NonTartget Means for each subclass
    M1est = list_M1{kk};
    M2est = list_M2{kk};      
    
    C.pattern(:,kk) = M2est - M1est;
    C.subC{kk} = comp_reg_cls2(C_invcov, M1est, M2est);
    
    if ~isfinite(C.subC{kk}.b)
        error('sth went wrong')
    end
end

if opt.ReturnRegularizationProfile
    %reorganize the regularization_list such that we can interpret them
%                the regul parameters are reordered such that (dat)
%                    l1  l2
%                    l3  l4
%                    l5  l6 
%                becomes a square Matrix A, which is better to interpret:
%                    (1-l1-l2)  l        l
%                      l3   (1-l3-l4)    l4
%                      l5       l6    (1-l5-l6)
    for i_class = 1:2 %for both classes       
        nPara = size(C.regularization_list,1)/2;
        dat = C.regularization_list((i_class-1)*nPara+1 : (i_class)*nPara,:)';
        A = zeros(size(dat,1));
        A(logical(eye(size(A)))) = 1-sum(dat,2);
        d = dat';
        A(~logical(eye(size(A)))) = d(:);
        C.regularization_profile{i_class} = A';
    end
end

return

end


function C = comp_reg_cls2(C_invcov, M1, M2)
C = [];
C.w= C_invcov*(M2 - M1);
C.b= -0.5*C.w'*(M2 + M1);
end

