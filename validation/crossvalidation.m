function [loss, lossSem, cfy_out]= crossvalidation(fv, classy, varargin)
%CROSSVALIDATION - Perform cross-validation
%
%Synopsis:
%  [LOSS, LOSSSEM]= crossvalidation(FV, CLASSY, <OPT>)
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
%   'LossFcn': Function handle of loss function, or CELL (+ parameters)
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

props = {'SampleFcn'   {@sample_KFold, [10 10]}   '!FUNC|CELL'
         'LossFcn'     @loss_0_1                  '!FUNC|CELL'
         'Proc'        []                         'STRUCT'
        };

if nargin==0;
  loss= props; return
end

opt= opt_proplistToStruct(varargin{:});

opt = opt_setDefaults(opt, props, 1);
misc_checkType(fv, 'STRUCT(x y)');
misc_checkType(fv.x, 'DOUBLE[2- 1]|DOUBLE[2- 2-]|DOUBLE[- - -]', 'fv.x');
misc_checkType(classy, 'FUNC|CELL');

opt.Proc= xvalutil_procSetDefault(opt.Proc);
[trainFcn, trainPar]= misc_getFuncParam(classy);
applyFcn= misc_getApplyFunc(classy);
[sampleFcn, samplePar]= misc_getFuncParam(opt.SampleFcn);
[divTr, divTe]= sampleFcn(fv.y, samplePar{:});
[lossFcn, lossPar]= misc_getFuncParam(opt.LossFcn);

xv_loss= zeros(length(divTr), 1);
xv_lossTr= zeros(length(divTr), 1);
nOutDim= size(fv.y,1);
if nOutDim==2,
  nOutDim= 1;
end
cfy_out= NaN*zeros(nOutDim, length(divTe), size(fv.y,2));
for rr= 1:length(divTr),
  nFolds= length(divTr{rr});
  fold_loss= zeros(nFolds, 1);
  fold_lossTr= zeros(nFolds, 1);
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
    out= applyFcn(C, reshape(fvTe.x, fvsz(1), []));
    cfy_out(:,rr,idxTe)= out;
    fold_loss(ff)= mean(lossFcn(fvTe.y, out, lossPar{:}));
    outTr= applyFcn(C, reshape(fvTr.x, fvsz));
    fold_lossTr(ff)= mean(lossFcn(fvTr.y, outTr, lossPar{:}));
  end
  xv_loss(rr)= mean(fold_loss);
  xv_lossTr(rr)= mean(fold_lossTr);
end
if nOutDim==1,
  cfy_out= reshape(cfy_out, [length(divTe), size(fv.y,2)]);
end
loss= mean(xv_loss);
lossSem= std(xv_loss)/sqrt(length(xv_loss));
lossTr= mean(xv_lossTr);
lossTrSem= std(xv_lossTr)/sqrt(length(xv_lossTr));
