function [loss, lossSem, cfy_out]= crossvalidation(fv, varargin)
%CROSSVALIDATION - Perform cross-validation
%
%Synopsis:
%  [LOSS, LOSSSEM]= crossvalidation(FV, CLASSY, <OPT>)
%  [LOSS, LOSSSEM]= crossvalidation(FV, <OPT>)
%
%Arguments:
%  FV -     Struct of feature vectors with data in field '.x' and labels in
%           field '.y'. FV.x may have more than two dimensions. The last
%           dimension is assumed to index samples. The labels FV.y must have
%           the format DOUBLE with size nClasses x nSamples.
%  CLASSY - Specification of the classifier. It can either simply be a
%           function handle, or a CELL {@FCN, PARAM1, PARAM2, ...}.
%  OPT -    Struct or property/value list of optional properties:
%   'SampleFcn': Function handle of sampling function, see functions
%           sample_*, or CELL providing also parameters of the samling
%           function), default @sample_KFold
%   'LossFcn': Function handle of loss function, CELL involving parameters 
%           {@FCN, PARAM1, PARAM2, ...}, or CELL array of function 
%           handles for multiple loss statistics (e.g. {@loss_0_1,
%           @loss_rocArea} ) - no parameters possible.
%   'ClassifierFcn': as direct input argument CLASSY, see above;
%           default @train_RLDAshrink
%   'Proc': Struct with fields 'train' and 'apply'. Each of those is a CELL
%           specifying a processing chain. See the example
%           demo_validation_csp to learn about this feature.
%
%Returns:
%  LOSS -   Loss averaged over all folds and repetitions
%  LOSSSEM - Standard error of the mean. First the loss is averaged across
%           all folds, and then the SEM across all shuffles is calculated.
%
% Examples:
%   loss = crossvalidation(fv, @train_RLDAshrink)
%   loss = crossvalidation(fv, @train_RLDAshrink, 'SampleFcn', {@sample_chronKFold, 5})
%
% cross-validation with CSP filter computation on training data:
%   proc = {}
%   proc.train= {{'CSPW', @proc_cspAuto, 3}
%                @proc_variance
%                @proc_logarithm
%               };
%   proc.apply= {{@proc_linearDerivation, '$CSPW'}
%                @proc_variance
%                @proc_logarithm
%               };
% 
%   crossvalidation(fv, {@train_RLDAshrink, 'Gamma',0}, ...
%                   'SampleFcn', {@sample_chronKFold, 8}, ...
%                   'Proc', proc)
 
% 2014-02 Benjamin Blankertz

props = {'SampleFcn'       {@sample_KFold, [10 10]}   '!FUNC|CELL'
         'LossFcn'         @loss_0_1                  '!FUNC|CELL'
         'ClassifierFcn'   @train_RLDAshrink          '!FUNC|CELL'
         'Proc'            []                         'STRUCT'
        };

if nargin==0;
  loss= props; return
end

if misc_isproplist(varargin{1}),
  opt= opt_proplistToStruct(varargin{:});
else
  opt= opt_proplistToStruct(varargin{2:end});
  opt.ClassifierFcn= varargin{1};
end

[opt,isdefault] = opt_setDefaults(opt, props, 1);
misc_checkType(fv, 'STRUCT(x y)');
misc_checkType(fv.x, 'DOUBLE[2- 1]|DOUBLE[1- 2-]|DOUBLE[- - -]', 'fv.x');

opt.Proc= xvalutil_procSetDefault(opt.Proc);
[trainFcn, trainPar]= misc_getFuncParam(opt.ClassifierFcn);
applyFcn= misc_getApplyFunc(opt.ClassifierFcn);
[sampleFcn, samplePar]= misc_getFuncParam(opt.SampleFcn);
[divTr, divTe]= sampleFcn(fv.y, samplePar{:});
[lossFcn, lossPar]= misc_getFuncParam(opt.LossFcn);

if isempty(lossPar)||~isa(lossPar{1}, 'function_handle')
    xv_loss= zeros(length(divTr), 1);
    xv_lossTr= zeros(length(divTr), 1);
else
    xv_loss= zeros(length(divTr), size(lossPar,2)+1);
    xv_lossTr= zeros(length(divTr), size(lossPar,2)+1);
end
nOutDim= size(fv.y,1);
if nOutDim==2,
  nOutDim= 1;
end
cfy_out= NaN*zeros(nOutDim, length(divTe), size(fv.y,2));
for rr= 1:length(divTr),
  nFolds= length(divTr{rr});
  if isempty(lossPar)||~isa(lossPar{1}, 'function_handle')
     fold_loss= zeros(nFolds, 1);
     fold_lossTr= zeros(nFolds, 1);
  else
     fold_loss= zeros(nFolds, size(lossPar,2)+1);
     fold_lossTr= zeros(nFolds, size(lossPar,2)+1);
  end
  for ff= 1:nFolds,
    idxTr= divTr{rr}{ff};
    idxTe= divTe{rr}{ff};
    
    fvTr= proc_selectSamples(fv, idxTr);
    if ~isempty(opt.Proc),
      [fvTr, memo]= xvalutil_proc(fvTr, opt.Proc.train);
    end
    xsz= size(fvTr.x);
    fvsz= [prod(xsz(1:end-1)) xsz(end)];
    C= trainFcn(reshape(fvTr.x,fvsz), fvTr.y, trainPar{:});
    
    fvTe= proc_selectSamples(fv, idxTe);
    if ~isempty(opt.Proc),
      fvTe= xvalutil_proc(fvTe, opt.Proc.apply, memo);
    end
    xsz= size(fvTe.x);
    out= applyFcn(C, reshape(fvTe.x, [prod(xsz(1:end-1)) xsz(end)]));
    cfy_out(:,rr,idxTe)= out;    
    outTr= applyFcn(C, reshape(fvTr.x, fvsz));
    if isempty(lossPar)||~isa(lossPar{1}, 'function_handle')
        fold_loss(ff)= mean(lossFcn(fvTe.y, out, lossPar{:}));
        fold_lossTr(ff)= mean(lossFcn(fvTr.y, outTr, lossPar{:}));
    else
        losstmp=[];
        losstmpTr=[];
        for ii=1:size(lossPar,2)
            losstmp=[losstmp mean(lossPar{ii}(fvTe.y, out))];
            losstmpTr=[losstmpTr mean(lossPar{ii}(fvTr.y, outTr))];
        end
        fold_loss(ff,:)= [mean(lossFcn(fvTe.y, out)) losstmp];
        fold_lossTr(ff,:)= [mean(lossFcn(fvTr.y, outTr)) losstmpTr];        
    end
  end
  xv_loss(rr,:)= mean(fold_loss);
  xv_lossTr(rr,:)= mean(fold_lossTr);
end
if nOutDim==1,
  cfy_out= reshape(cfy_out, [length(divTe), size(fv.y,2)]);
end
loss= mean(xv_loss,1);
lossSem= std(xv_loss,0,1)/sqrt(size(xv_loss,1));
lossTr= mean(xv_lossTr,1);
lossTrSem= std(xv_lossTr,0,1)/sqrt(size(xv_lossTr,1));
