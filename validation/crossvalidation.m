function [loss, lossStd]= crossvalidation(fv, classy, varargin)

props = {'SampleFcn'   @sample_divisions    'FUNC|CELL'
         'XTrials'     [10 10]              'DOUBLE[1 2]'
         'LossFcn'     @loss_0_1            'FUNC|CELL'
         'Proc'        []                   'STRUCT'
        };

if nargin==0;
  xv_loss= props; return
end

if length(varargin)>0 && isnumeric(varargin{1}),
  varargin= {'XTrials', varargin{:}};
end
opt= opt_proplistToStruct(varargin{:});

[opt,isdefault] = opt_setDefaults(opt, props);
opt_checkProplist(opt, props);
misc_checkType(fv, 'STRUCT(x y)');
misc_checkType(fv.x, 'DOUBLE[2- 1]|DOUBLE[2- 2-]|DOUBLE[- - -]', 'fv.x');
misc_checkType(classy, 'FUNC|CELL');

opt.Proc= xvalutil_procSetDefault(opt.Proc);
[trainFcn, trainPar]= misc_getFuncParam(classy);
applyFcn= misc_getApplyFunc(classy);
[sampleFcn, samplePar]= misc_getFuncParam(opt.SampleFcn);
[divTr, divTe]= sampleFcn(fv.y, opt.XTrials, samplePar{:});
[lossFcn, lossPar]= misc_getFuncParam(opt.LossFcn);

xv_loss= zeros(length(divTr), 1);
xv_lossTr= zeros(length(divTr), 1);
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
    xsz= size(fvTe.x);
    out= applyFcn(C, reshape(fvTe.x, [prod(xsz(1:end-1)) xsz(end)]));
    fold_loss(ff)= mean(lossFcn(fvTe.y, out, lossPar{:}));
    outTr= applyFcn(C, reshape(fvTr.x, fvsz));
    fold_lossTr(ff)= mean(lossFcn(fvTr.y, outTr, lossPar{:}));
  end
  xv_loss(rr)= mean(fold_loss);
  xv_lossTr(rr)= mean(fold_lossTr);
end

loss= mean(xv_loss);
lossSem= std(xv_loss)/sqrt(length(xv_loss));
lossTr= mean(xv_lossTr);
lossTrSem= std(xv_lossTr)/sqrt(length(xv_lossTr));
