function [outarg1, loss_std, out_test, memo]= xvalidation(epo, model, varargin)
%[loss, loss_std, out_test, memo]= xvalidation(fv, model, <opt>)
%
% IN  fv      - features vectors, struct with fields
%               .x (data, nd array where last dim is nSamples) and
%               .y (labels [nClasses x nSamples], 1 means membership)
%     model   - name or structure specifying a classification model,
%               cd to /classifiers and type 'help Contents' to see a list.
%               if the model has free parameters, they are chosen by
%               select_model on each training set (default, time consuming),
%               or by calling select_model beforehand, see opt.Outer_ms
%               (quicker, but can bias the estimation of xvalidation loss).
%     opt:
%     .sample_fcn   - FUNC: handle to the function that is called to randomly
%                     draw training / test set splits (prefix 'sample_' is
%                     automatically prepended). The dataset is usually
%                     partitioned into #folds equisized folds, with 1 fold being 
%                     used for validation(test) and the other #folds-1 for training. 
%                     This is usually repeated #folds times, so that each
%                     single fold served for validation. If there are
%                     multiple shuffles, this procedure is repeated
%                     #shuffles times.
%                     Examples (default @sample_divisions): 
%                     @sample_divisions      - in each fold, between-class ratios (ie, the relative number of samples per class) are preserved 
%                     @sample_kfold          - random partitioning of the samples into folds, class memberships are ignored
%                     @sample_chronKfold     - partitioning in chronological order instead of random. Multiple #shuffles are not possible and will be ignored.
%                     @sample_chronKKfold    - ?
%                     @sample_chronSplit     - ?
%                     @sample_leaveOneOut    - validation on single sample, training on rest. This is repeated for each sample.
%                     @sample_evenOdd        - split training samples alternately. Esp. for small training sets: used for checking, if single outliers produce a bias.
%                     @sample_fixedTrainsize - you can specify a fixed size for the training set (for each class). Validation is performed on the remaining data.
%                     @sample_divisionsEqui  - ??
%                     @sample_divisionsPlus  - ??
%                     Can also be a cell array, where the first cell holds
%                     the name of the function as string, and the following
%                     cells hold parameters that are passed to the
%                     sample_fcn.
%     .xTrials      - <'xTrials', xt> is a short cut for
%                     <'sample_fcn', {'divisions', xt}>. The value xt is a
%                     vector [#shuffles, #folds], see sample_divisions,
%                     default [10 10].
%     .LossFcn       - FUNC (handle to loss function), or cell array {@loss_fcn, loss_param},
%                     e.g., @loss_0_1 (default), @loss_classwiseNormalized, @loss_identity,
%                     {'byMatrix', loss_matrix}
%                     if first choice would call the function loss_0_1 to
%                     determine the loss, the last choice would call
%                     loss_byMatrix and pass the argument loss_matrix.
%                     The loss function 'identity' can be used to
%                     evaluate likelihoods, see LOSS_IDENTITY. For this
%                     loss function, EPO.y is effectively ignored and
%                     thus need not be provided.
%     .ms_sample_fcn- like sample_fcn but to be used in model selection.
%     .msTrials     - like xTrials, but for model selection. when the third
%                     value is -1 it is set to the size of the training set
%                     (useful for outer model selection), default [3 10]
%                     without .outer_ms and [3 10 -1] with .outer_ms.
%     .outer_ms     - perform model selection before the xvalidation.
%                     this can bias the estimation of the xvalidation loss.
%                     should not be done on the whole set, e.g., by
%                     choosing opt.MsTrials= [3 10 -1]. default 0.
%     .divTr,.divTe - specified fixed training / test set splits
%                     format must be as the output of the sample_* functions.
%                     if this field is given .sample_fcn is (of course)
%                     ignored.
%                     alternatively these fields can be added to the fv
%                     structure (first argument)
%     .msdivTr, .msdivTe - specified fixed training / test set splits for
%                     outer model selection (only possible is .outer_ms=1),
%                     otherwise the same as above.
%     .proc         - class dependent preprocessing; this string is
%                     evaluated for each training set (labels of the test
%                     set are set to NaN),
%                     the procedure must calculate 'fv' from 'fv'.
%                     Obsolete is to use a procedure which calculates
%                     'fv' from 'epo'. This still works, but maybe will
%                     be restricted in future versions.
%                     (field proc can also be given in fv structure)
%                     EXTENDED to free parameters, to be explained.
%     .out_trainloss- output not only test but also training loss. in this
%                     case loss and loss_std are 2-d vectors, default 0.
%     .std_of_means - if true output loss_std is calculated as std of the
%                     means of the losses of each fold, default 1.
%     .classifier_nargout - specify the number of output-arguments to
%                     receive from the applyFcn. If this is set > 1 then
%                     out_test is made a structure with a field for each
%                     argout and all nargouts are passed to the loss_fcn 
%                     (which needs to be able the handle them). All argouts
%                     are assumed to be row-vectors with one number for
%                     each test point, like the usual continous classifier-out.
%     .catch_trainerrors - if true, errors when calling the training
%                     routine do not cause xvalidation to stop. Instead,
%                     the respective predictions will be set of NaN. Mind
%                     that errors during model selection will still cause
%                     xvalidation to abort. default 0.
%     .allow_reject - if true, classifier outputs that are NaN will be
%                     interpreted as "rejected" (can not be classified
%                     with minimum level of certainty). See below for
%                     changes in the output of xvalidation. default: 0
%     .allow_transduction - if true, also the samples of the test set are
%                     passed to the classifier, but (of course) with NaN'ed
%                     labels, default 0.
%     .verbosity    - level of verbosity (0: silent, 1: normal,
%                     2: show intermediate results of model selection)
%     .save_classifier - saves the classifier that was selected by an
%                     inner model selection into the memo output variable,
%                     default 0.
%     .save_proc    - saves the processing that was selected by an inner
%                     process selection into the memo output variable.
%     .save_proc_params - a cell array of variable names that are free
%                     variables or output variables of opt.proc and that
%                     were selected by an inner process selection into
%                     the memo output variable.
%     .save_file    - a name of a file intermediate results will be saved, too.
%                     If this fields is defined, a restart of this programm
%                     will start at the point the last intermediate result
%                     was saved. This is important for condor.
%     .clock        - show a work progress clock (in figure)
%     .progress_bar - show a work progress bar (in terminal)
%     .out_timing   - prints out elapsed time, default 1.
%     .out_prefix   - a string that is printed before the result
%                     (unfinished lines printed before calling xvalidation
%                     are possibly erased by the progress bar)
%     .train_only   - return (as first output argument instead of loss)
%                     trained classifiers (in a cell array) for each fold
%                     of the  cross-validation. classifiers are not
%                     applied to the test sets.
%     .train_jits   - for training use only samples with those jitter
%                     indices (requires that fv has field jit)
%     .test_jits    - for testing use only samples with those jitter
%                     indices (requires that fv has field jit)
%     .fp_bound     - <do we still need this?>
%
%     .twoClass2Bool - if true (default) and nClasses == 2 xvalidation will 
%                      detect the binary problem and change fv.y to a
%                      vector [1 x nSamples] with 0/1.
%
% OUT loss      - loss of the test set
%                 if opt.out_trainloss is true, [loss_test, loss_train]
%     loss_std  - analog, see opt.std_of_means
%     out_test  - continuous classifier output for each x-val trial /
%                 sample, a matrix of size [nClasses nSamples nTrials].
%                 For classifiers with reject option: see below.
%     memo      - according to opt.save_classifier, opt.save_proc, and
%                 opt.save_proc_params saves some of the selections that
%                 are made by a model/process selection within the
%                 cross-validation.
%
% You can make 'equivalence classes' of samples by adding a field 'bidx'
% (= 'base index') to the fv. This must be a vector of length #samples
% specifying an index of equivalence class. This has the effect that
% all samples that belong to one equivalence classes (i.e., they have
% the same index) are either *all* put into the training set or
% *all* put into the test set. In this case indices in the training /
% test set splits refer to these indices of equivalence classes.
%
% To make further evaluations of the output, you can call functions
% from the family val_*, e.g,
%   val_rocCurve to plot a ROC curve,
%   val_confusionMatrix to calculate the confusion matrix,
%   val_compareClassifiers to see whether your result is 'significantly'
%                          better than chance, ...
%
% If you want to reject outliers, you have to implement a function
% proc_outl_* that has as input and output a fv structure, which sets
% the labels (field .y) of rejected trials to 0 or NaN. Then set
% opt.proc to 'fv= proc_outl_*(fv, <possible_some_parameters>);'.
% Caveat: the loss on the training set (which can display by setting
% opt.out_trainloss to 1) is then calculated on the *accepted trials only*.
% Future versions of xvalidation may allow also to reject samples to
% the test sets.
%
% XVALIDATION with the allow_reject option handles classifiers that can
% reject samples in the apply phase (for example, if an example can not be
% classified with a minimum certainty). Rejected samples need to be marked
% as NaNs in the classifier output. With this option set, output variable
% out_test is a structure with 2 fields:
%   'out': the continuous classifier output as a matrix of size
%     [nClasses nSamples nTrials] (or [1 nSamples nTrials] for 2 classes)
%   'valid': a logical array of size [nSamples nTrials].
%     out_test.valid(i,j)==1 means that example i has not been rejected in the
%     j.th cross-validation trial.
% Mind that some of the samples may not have been used as test
% examples. Such examples are also marked by NaNs in out_test, but their
% corresponding out_test.valid entry is 1.
% Rejected samples are passed to the loss function without any
% modification. Make sure that the loss function handles rejected samples
% in a meaningful way.
%
%
% SEE select_model, select_proc, sample_kfold, sample_divisions, loss_0_1, loss_identity

% Benjamin Blankertz
% with extensions by guido, anton numerous others

props = { 'SampleFcn'           @sample_divisions       'FUNC|CELL';
          'XTrials',            [10 10],                'DOUBLE[1 2]';
          'LossFcn',            @loss_0_1,              'FUNC|CELL';
          'MsSampleFcn'         @sample_divisions       'FUNC|CELL';
          'MsTrials'            [3 10]                  'DOUBLE[1 2]|DOUBLE[1 2 1]';
          'OuterMs'             0                       'DOUBLE';
          'OutTrainloss'        0                       '!BOOL';
          'OutTiming'           0                       '!BOOL';
          'OutSampling'         0                       '!BOOL';
          'OutPrefix'           ''                      'CHAR';
          'StdOfMeans'          1                       '!BOOL';
          'ClassifierNargout'   1                       '!INT';
          'AllowReject'         0                       '!BOOL';
          'CatchTrainerrors'    0                       '!BOOL';
          'TrainOnly'           0                       '!BOOL';
          'BlockMarkers'        []                      ''; % ??
          'Proc'                ''                      'STRUCT';
          'FpBound'             0                       ''; % ??
          'AllowTransduction'   0                       '';
          'Verbosity',          1                       '!BOOL';
          'Clock'               0                       '!BOOL';
          'SaveFile'            ''                      'CHAR';
          'ProgressBar'         1                       '!BOOL';
          'DivTr'               []                      'DOUBLE';
          'MsDivTr'             []                      'DOUBLE';
          'SaveClassifier'      0                       '!BOOL';
          'SaveProc'            0                       '!BOOL';
          'SaveProcParams'      []                      'CELL{CHAR}';
          'Debug'               0                       '!BOOL';
          'DsplyPrecision'      3                       'DOUBLE';
          'DisplayPlusMinus'     char(177)               'CHAR';
          'TwoClass2Bool'       1                       '!BOOL';          
         };

       
if nargin==0,
  outarg1= props; return
end


if length(varargin)==1 && isreal(varargin{1}),
  opt.XTrials= varargin{1};
else
  opt= opt_proplistToStruct(varargin{:});
end

[opt,isdefault] = opt_setDefaults(opt, props);
opt_checkProplist(opt, props);
misc_checkType(epo,'STRUCT(x y)');
misc_checkType(epo.x,'DOUBLE[2- 1]|DOUBLE[2- 2-]|DOUBLE[- - -]','epo.x');
misc_checkType(model,'STRUCT|CHAR|FUNC');

t0= cputime;

if isfield(epo, 'y'),
  % Standard case with given labels:
  labelsProvided = 1;
  [nClasses, nSamples]= size(epo.y);
  % Class labels could also be logicals. Nice in principle, but later we
  % will set some class labels to NaN, and this is not possible with
  % logicals.
  if islogical(epo.y),
    epo.y = double(epo.y);
  end
else
  % No labels given: Assume that the task is to evaluate likelihoods. Create a
  % dummy label field, so that all subsequent code works without change. To
  % make the various sampling procedures work nicely, I create a dummy field
  % indicating that everything is from one class
  labelsProvided = 0;
  nSamples = size(epo.x, ndims(epo.x));
  nClasses = 1;
  epo.y = ones([nClasses nSamples]);
end


%                 'dsply_plusminus', '+/-');

% In the implementation, the progress_bar option overrides
% verbosity. Fix this, so that nothing is displayed with verbosity==0 and
% progress_bar unchanged from its default
if opt.Verbosity<1 && isdefault.ProgressBar,
  opt.ProgressBar = 0;
end
if isequal(opt.MsSampleFcn, @sample_divisions),
  if opt.OuterMs && isdefault.MsTrials,
    if isfield(opt, 'XTrials'),
      opt.MsTrials= [opt.XTrials(1:2) -1];
    else
      opt.MsTrials= [3 10 -1];
    end
  end
  opt.MsSampleFcn= {opt.MsSampleFcn, opt.MsTrials};
else
  if ~isdefault.MsTrials,
    msg= 'property .msTrials is ignored when you specify .ms_sample_fcn';
    util_warning(msg, 'validation', mfilename);
  end
end
if isequal(opt.SampleFcn, @sample_divisions),
  opt.SampleFcn= {opt.SampleFcn, opt.XTrials};
  opt= rmfield(opt, 'XTrials');
else
  if ~isdefault.XTrials,
    msg= 'property .XTrials is ignored when you specify .SampleFcn';
    util_warning(msg, 'validation', mfilename);
  end
end
opt= rmfield(opt, 'MsTrials');

if isfield(epo, 'proc'),
  if ~isempty(opt.Proc),
    error('field proc must either be given in fv or opt argument');
  end
  opt.Proc= epo.proc;
  epo= rmfield(epo, 'proc');
end

if ~isempty(opt.Proc) && isstruct(opt.Proc),
  if isfield(opt.Proc, 'eval'),
    if isfield(opt.Proc, 'train') || isfield(opt.Proc, 'apply'),
      error('proc may either have field eval XOR fields .train/.apply');
    end
  else
    if ~isfield(opt.Proc, 'train'),
      opt.Proc.train= '';
    end
    if ~isfield(opt.Proc, 'apply'),
      opt.Proc.apply= '';
    end
  end
end
if opt.Debug,
  if isdefault.ProgressBar,
    opt.ProgressBar= 0;
  end
  persistent counter
  if opt.Debug==1,
    counter= 1;
  else
    counter= counter+1;
  end
  fprintf('xv (#%d, depth %d), %s', counter, opt.Debug, ...
          util_toString(opt.SampleFcn));
  if prochasfreevar(opt.Proc),
    fprintf(', ');
    if opt.OuterMs,
      fprintf('outer');
    end
    fprintf('proc selection');
  elseif isfield(opt.Proc, 'pvi'),
    fprintf(', proc indices %s', str_vec2str(opt.Proc.pvi));
  end
  if isstruct(model),
    fprintf(', ');
    if opt.OuterMs,
      fprintf('outer');
    end
    fprintf('model selection');
  end
  fprintf('\n');
  opt.Debug= opt.Debug+1;
end

if opt.SaveProc && ~prochasfreevar(opt.Proc),
  msg= 'save_proc makes only sense for .proc with free variables';
  util_warning(msg, 'validation', mfilename);
  opt.SaveProc= 0;
end

if isfield(epo, 'divTr'),
  if ~isempty(opt.DivTr),
    error('divTr is given in both, fv and opt argument');
  end
  opt.DivTr= epo.divTr;
  opt.DivTe= epo.divTe;
  epo= rmfield(epo, {'divTr','divTe'});
end

if isfield(epo, 'msdivTr'),
  if ~isempty(opt.MsDivTr),
    error('msdivTr is given in both fv and opt argument');
  end
  opt.MsDivTr= epo.msdivTr;
  opt.MsDivTe= epo.msdivTe;
  epo= rmfield(epo, {'msdivTr','msdivTe'});
end
if ~isempty(opt.MsDivTr) && ~opt.OuterMs,
  error('msdivTr can only be specified for outer model selection');
end

fmt= ['%.' int2str(opt.DsplyPrecision) 'f'];

opt= opt_setDefaults(opt, {'CheckBidxLabels',~isfield(opt,'DivTr')});

if isfield(epo, 'bidx'),
  [repIdx, eqcl]= xval_choose_repIdx(epo, opt.CheckBidxLabels);
else
  % "Normal" data without bidx: Need to distinguish between regression
  % and classification here. For regression, epo.y might take on the
  % value zero, kicking that effectively sample out 
  if size(epo.y,1)==1 && length(unique(epo.y))>2,
    isRegression = 1;
    repIdx = 1:length(epo.y);
  else
    isRegression = 0;
    repIdx= find(any(epo.y,1));
  end
  % bidx binds samples to equivalence classes.
  % Non-valid samples are bound to class "0", which is never sampled.
  epo.bidx = zeros(1, size(epo.y,2));
  epo.bidx(repIdx) = repIdx;
  eqcl = repIdx;
end
if ~isfield(epo, 'jit'),
  epo.jit= zeros(size(epo.bidx));
end

opt= set_defaults(opt, ...
                  'TrainJits', unique(epo.jit), ...
                  'TestJits', unique(epo.jit));


save_interm_vars = {};
opt_ms= [];
%if ~isstruct(model),   %% classifier without free hyper parameters
%  classy= model;
%  model= [];
%end
if prochasfreevar(opt.Proc) || isstruct(model),
  %% either selection of pre-processing parameter or selection
  %% of classification model is required
  opt_ms= rmfield(opt, {'SaveFile','SaveProc','SaveClassifier',...
                        'TrainOnly'});
  opt_ms.Clock= 0;
  opt_ms.Verbosity= max(0, opt.Verbosity-1);
  opt_ms.SampleFcn= opt.MsSampleFcn;
  opt_ms.DivTr= opt.MsDivTr;
  if isfield(opt, 'MsDivTe'),
    opt_ms.DivTe= opt.MsDivTe;
  end
  if opt.OuterMs,
    loaded = 0;
    if ~isempty(opt.SaveFile) && exist([opt.SaveFile,'.mat'],'file')
      S = load(opt.SaveFile);
      if isfield(S,'classy')
        load(opt.SaveFile);
        loaded = 1;
      end
    end
    if loaded==0
      if opt.Verbosity>0,
        msg= 'outer model selection can bias the results';
        util_warning(msg, 'validation', mfilename);
      end
      if opt.Verbosity<2,
        opt_ms.progress_bar= 0;
      end
      opt_proc_memo= opt.Proc;
      %      if isstruct(opt.Proc) & isfield(opt.Proc, 'train'),
      %        proc= rmfield(opt.Proc, {'train','apply'});
      %        proc.eval= opt.Proc.train;
      %        [proc, classy, ml, mls]= select_proc(epo, model, proc, opt_ms);
      %        if isfield(proc, 'param'),
      %          opt.Proc.param= proc.param;
      %        end
      %      else
      [opt.Proc, classy, ml, mls]= select_proc(epo, model, opt.Proc, opt_ms);
      %      end
      if ~isequal(opt.Proc, opt_proc_memo) && opt.Verbosity>0,
        fprintf('select_proc chose: ');
        disp_proc(opt.Proc);
      end
      if isstruct(model),
        if opt.Verbosity>0,
          fprintf(['chosen classifier: %s -> ' ...
                   fmt opt.DisplayPlusMinus fmt '\n'], ...
                  util_toString(classy), ml(1), mls(1));
        end
      end
      model= [];  %% model has been chosen -> classy
      if ~isempty(opt.SaveFile)
        save_interm_vars = {'opt_proc_memo','classy','ml','mls','opt','model'};
        save(opt.SaveFile,save_interm_vars{:},'save_interm_vars');
      end
    end
  else  %% i.e., not opt.outer_ms
    opt_ms.verbosity= 0;
    opt_ms.progress_bar= 0;
    if isstruct(model),
      classy= model.classy;  %% This is defined only to get the names,
                             %% the parameters have to determined on the
                             %% training sets within the cross-validation.
    else
      classy= model;
      model= [];
    end
  end
else              %% classification model without free hyper parameters
  classy= model;
  model= [];
end

% this is a quick fix : classy should be actually a handle throughout...
if isa(classy,'function_handle')
    [dummy, train_par]= misc_getFuncParam(classy);
    train_fcn= classy;
    dummy= func2str(classy);
    applyFcn= misc_getApplyFunc(str_tail(dummy,'_'));
else 
    [dummy, train_par]= misc_getFuncParam(classy);
    train_fcn = str2func(['train_' classy]);
    applyFcn= misc_getApplyFunc(classy);
end
[loss_fcn, loss_par]= misc_getFuncParam(opt.LossFcn);

% Issue a warning if 'loss_identity' is used with labels given, as the
% labels will be ignored in this case
if isequal(loss_fcn, @loss_identity) && labelsProvided,
  warning('With loss function LOSS_IDENTITY, labels EPO.y will be ignored.');
end

if opt.FpBound~=0 && ~isequal(applyFcn, @apply_separatingHyperplane),
  error('FP-bound works only for separating hyperplane classifiers');
end

if ~isempty(opt.DivTr),
  divTr= opt.DivTr;
  %% special feature: when divTr is given, but not divTe: take as test
  %% samples all those, which are not in the training set.
  if ~isfield(opt, 'divTe') && ~opt.TrainOnly,
    opt.DivTe= cell(1,length(divTr));
    for nn= 1:length(divTr),
      opt.DivTe{nn}= cell(1,length(divTr{nn}));
      for kk= 1:length(divTr{nn}),
        opt.DivTe{nn}{kk}= setdiff(1:max(eqcl), opt.DivTr{nn}{kk});
      end
    end
  end
  divTe= opt.DivTe;
  for i = 1:length(opt.DivTr)
    for j = 1:length(opt.DivTr{i})
      for k = 1:length(opt.DivTr{i}{j})
        divTr{i}{j}(k) = find(eqcl==opt.DivTr{i}{j}(k));
      end
      if ~opt.TrainOnly
        for k = 1:length(opt.DivTe{i}{j})
          divTe{i}{j}(k) = find(eqcl==opt.DivTe{i}{j}(k));
        end
      else
        divTe{i}{j} = [];
      end
    end
  end
  sample_fcn= 'given sample partitions';
  sample_params= {};
else
  [sample_fcn, sample_params]= misc_getFuncParam(opt.SampleFcn);
  [divTr, divTe]= sample_fcn(epo.y(:,repIdx), sample_params{:});
end
check_sampling(divTr, divTe);

if isfield(epo, 'equi') || ...
        (isfield(opt, 'equi') && ~isequal(sample_fcn, @sample_divisionsEqui)),
    error(['field equi must now be passed in opt structure within the field ' ...
        'sample_params and sample_fcn must be divisionsEqui']);
end

label= epo.y;

%#########################################
% exception for binary classification tasks
%
%  changed by stl at 18.02.2005
%

if (opt.ClassifierNargout > 1),
  %%% avoid calling loss_fcn b.c. classifier output is not yet available
  %%%
  %%% does 1 or 0 make more sense here?
  loss_samplewise= 1;
else
  if size(label) == 2, % shouldn't this rather be "size(label,1) == 2" ?? (Michael, 2012_07_10)
    l= loss_fcn(label, label(1,:), loss_par{:});
  else
    l= loss_fcn(label, epo.y, loss_par{:});
  end ;
  %#########################################
  loss_samplewise= (length(l)>1);
end

if ~loss_samplewise,
  if opt.OutTrainloss,
    msg= sprintf('trainloss cannot be returned for loss <%s>', func2str(loss_fcn));
    util_warning(msg, 'validation', mfilename);
    opt.OutTrainloss= 0;
  end
end

nTrials= length(divTe); % for better understanding, consider renaming "nTrials" with "nShuffles"
if ~opt.TrainOnly,
    avErr= NaN*zeros(nTrials, length(divTe{1}), opt.OutTrainloss+1);
    if opt.TwoClass2Bool
      out_test= NaN*zeros([nClasses-(nClasses==2), nSamples, nTrials]);
    else
      out_test= NaN*zeros([nClasses, nSamples, nTrials]);      
    end
    % Store for each sample whether the classifier has produced a valid
    % output, i.e., it has not rejected the sample.
    out_valid = logical(ones([nSamples nTrials]));

    % Make a cell array for all the classifier output apart from the
    % first one (the first output arg is handled by the old xvalidation
    % code, don't want to touch that)
    more_out_test = cell([1 opt.ClassifierNargout-1]);
    for tmp = 1:length(more_out_test),
      if opt.TwoClass2Bool
        more_out_test{tmp} = NaN*zeros([nClasses-(nClasses==2), nSamples, nTrials]);
      else
        more_out_test{tmp} = NaN*zeros([nClasses, nSamples, nTrials]);        
      end
    end
end

memo= [];

if ~isempty(opt.SaveFile) & exist([opt.SaveFile,'.mat'],'file')
    load(opt.SaveFile);
    if ~exist('n','var')
        n0 = 1;
        d0 = 1;
    else
        n0 = n;
        d0 = d+1;
    end
else
    n0 = 1;
    d0 = 1;
end

if ~isfield(epo,'classifier_param')
    epo.classifier_param = {};
end

if opt.ProgressBar, tic; end
for n= n0:nTrials,
    nDiv= length(divTe{n});  %% might differ from nDivisions in 'loo' case
    usedForTesting = logical(zeros([1 size(out_test,2)]));
    for d= d0:nDiv,
        if opt.Debug==2 && (isstruct(model) || prochasfreevar(opt.Proc)),
            fprintf('xv: division [%d %d]\n', n, d);
        end
        k= d+(n-1)*nDiv;
        bidxTr= divTr{n}{d};
        bidxTe= divTe{n}{d};
        idxTr= find(ismember(epo.bidx, epo.bidx(repIdx(bidxTr))) & ...
            ismember(epo.jit, opt.TrainJits));
        idxTe= find(ismember(epo.bidx, epo.bidx(repIdx(bidxTe))) & ...
            ismember(epo.jit, opt.TestJits));
        epo.y(:,idxTe)= NaN;              %% hide labels of the test set

        if ~isempty(model),               %% do model selection on training set
            fv= xval_selectSamples(epo, idxTr);
            [best_proc, classy, E, V,ms_memo]= select_proc(fv, model, opt.Proc, opt_ms);
            memo.ms_memo{n}{d} = ms_memo; % keep memo from model selection for post-observations
            if prochasfreevar(best_proc),
                error('not all free variable were bound');
            end
            [func, train_par]= getFuncParam(classy);
        elseif prochasfreevar(opt.Proc),
            fv= xval_selectSamples(epo, idxTr);
            %      if isstruct(opt.proc) & isfield(opt.proc, 'train'),
            %        proc= rmfield(opt.proc, {'train','apply'});
            %        proc.eval= opt.proc.train;
            %      else
            %        proc= opt.proc;
            %      end
            best_proc= select_proc(fv, classy, opt.Proc, opt_ms);
            if prochasfreevar(best_proc),
                error('not all free variable were bound');
            end
        else
            best_proc= opt.Proc;
        end
        % Select the data points for train and test for the current fold, and separately apply the preprocessing functions
        idxTrTe= [idxTr, idxTe];
        iTr= 1:length(idxTr);
        iTe= length(idxTr) + [1:length(idxTe)];
        if isstruct(best_proc) && isfield(best_proc, 'train'),
            fv1= xval_selectSamples(epo, idxTr);
            proc= rmfield(best_proc, {'train','apply'});
            proc.eval= best_proc.train;
            [fv1, proc]= proc_applyProc(fv1, proc);
            proc.eval= best_proc.apply;
            fv2= xval_selectSamples(epo, idxTe);
            fv2= proc_applyProc(fv2, proc);
            fv= proc_appendSamples(fv1, fv2);
            clear fv1 fv2;
            if isfield(proc, 'param'),
              best_proc.param= proc.param;
            end
        else
            fv= xval_selectSamples(epo, idxTrTe);
            fv= proc_applyProc(fv, best_proc);
        end
        fv= proc_flaten(fv);
        if size(fv.x,2)~=length(idxTrTe),
            error('number of samples was changed thru opt.Proc!');
        end

        %% TODO: allow rejection of test samples ( -> performance criterium!)
        %    iRejectTe= find(any(isnan(fv.y(:,iTe))));
        iRejectTr= find(~any(fv.y(:,iTr)) | any(isnan(fv.y(:,iTr))));
        iTr(iRejectTr)= [];

        if opt.AllowTransduction,
          %% pass also samples of the test set to the classifier
          %% (but with NaN'ed labels, of course)
          ff= xval_selectSamples(fv, [iTr iTe]);
        else
          ff= xval_selectSamples(fv, iTr);
        end
        if opt.CatchTrainerrors,
          try
            C= train_fcn(ff.x, ff.y, ff.classifier_param{:},train_par{:});
          catch
            if opt.Verbosity>0,
              fprintf('Failed to train classifier in division [%d %d]\n', n, d);
            end
            C = [];
          end
        else
          C= train_fcn(ff.x, ff.y, ff.classifier_param{:},train_par{:});
        end
        epo.y= label;

        if opt.FpBound && ~isempty(C),
            iTeNeg=  iTe(find(epo.y(1,idxTe)));
            frac= floor(length(iTeNeg)*fp_bound);
            xp= C.w'*fv.x(:,iTeNeg);
            [so,si]= sort(-xp);
            C.b= so(frac+1) - eps;
        end
        if nargout>3,
            if opt.SaveClassifier,
                memo(k).C= C;
                memo(k).classy= classy;
            end
            if opt.SaveProc,
                memo(k).proc= best_proc;
            elseif ~isempty(opt.SaveProcParams),
                for fi= 1:length(opt.SaveProcParams),
                    fld=  opt.SaveProcParams{fi};
                    ip= strmatch(fld, {best_proc.param.var},'exact');
                    if isempty(ip),
                        msg= sprintf('variable %s not found', fld);
                        error(msg);
                    end
                    memo= setfield(memo, {k}, fld, ...
                        best_proc.param(ip).value{1});
                end
            end
        end
        if opt.TrainOnly,
            outarg1(k)= C;
            if ~isempty(opt.SaveFile)
                save(opt.SaveFile,save_interm_vars{:},'n','d','divTr','divTe', ...
                    'memo','outarg1','save_interm_vars');
            end

        elseif ~isempty(C),
          % Outputs (out_test) already have NaN as default values. If training failed,
          % we don't need to do anything
          
          % A cell array to catch potential extra classfier outputs
          more_out = cell([1 opt.ClassifierNargout-1]);
          if opt.OutTrainloss,
            [out more_out{:}]= applyFcn(C, fv.x);
            out_test(:, idxTe, n)= out(:,iTe);
            usedForTesting(idxTe) = 1;
            if (opt.ClassifierNargout > 1),
              for tmp_num = 1:(opt.ClassifierNargout-1),
                more_out_test{tmp_num}(:, idxTe, n) = more_out{tmp_num}(:,iTe);
              end
            end
            if loss_samplewise,
              loss= loss_fcn(label(:,idxTrTe), out, more_out{:}, loss_par{:});
              avErr(n,d,1)= mean(loss(iTe));
              avErr(n,d,2)= mean(loss(iTr));
            else
              avErr(n,d,2)= loss_fcn(label(:,idxTr), out(iTr), loss_par{:});
            end
          else
            [out more_out{:}]= applyFcn(C, fv.x(:,iTe));
            out_test(:, idxTe, n)= out;
            usedForTesting(idxTe) = 1;
            if (opt.ClassifierNargout > 1),
              for tmp_num = 1:(opt.ClassifierNargout-1),
                more_out_test{tmp_num}(:, idxTe, n)= more_out{tmp_num};
              end
            end
            if loss_samplewise,
              loss= loss_fcn(label(:,idxTe), out, more_out{:}, loss_par{:});
              avErr(n,d,1)= mean(loss);
            end
          end
          if opt.AllowReject,
            % Check for rejected samples: All classifier outputs need to be
            % NaN for rejected samples
            rejected = all(isnan(out), 1);
            out_valid(idxTe(rejected), n) = 0;
          end
          if ~isempty(opt.SaveFile)
            save(opt.SaveFile,save_interm_vars{:},'n','d','divTr','divTe',...
                 'avErr','out_test', 'more_out_test', 'memo','out_valid','save_interm_vars');
          end
        end
        if opt.ProgressBar, util_printProgress(k, nDiv*nTrials); end
        if opt.Clock, showClock(k, nDiv*nTrials); end
    end %% for d
    d0 = 1;
    if ~loss_samplewise,
      more_out_test_subset = {};
      % Subset all extra output arguments to those examples that were
      % ever used for testing
      for i_out = 1:length(more_out_test),
        more_out_test_subset = more_out_test{i_out}(:,usedForTesting,n);
      end
      avErr(n,:,1)= loss_fcn(label(:,usedForTesting), ...
                             out_test(:,usedForTesting,n), ...
                             more_out_test_subset{:}, loss_par{:});
    end
end %% for n
if opt.TrainOnly,
    return;
end

et= cputime-t0;
avE = mean(avErr,2);
avErr = reshape(avErr,[nTrials*length(divTe{1}), opt.OutTrainloss+1]);
loss_mean= mean(avErr, 1);

outarg1= loss_mean;
if opt.StdOfMeans && loss_samplewise,
    loss_std= transpose(squeeze(std(avE, 0, 1)));
else
    loss_std= std(avErr, 0, 1);
end

% Make up the output for the case that some examples have been rejected
% by the classifier or more output arguments are to be taken care of
if opt.AllowReject || (opt.ClassifierNargout > 1),
  out_test = struct('out', out_test);
  if opt.AllowReject,
    out_test.valid = out_valid;
  end
  if (opt.ClassifierNargout > 1),
    out_test.more_out = more_out_test;
  end
end

if nargout==0 || opt.Verbosity>0,
    if opt.OutSampling,
        if strcmp(sample_fcn, 'given sample partitions'),
            smplStr= sample_fcn;
        else
            smplStr= util_toString(sample_params);
            smplStr= sprintf('%s: %s', sample_fcn, smplStr(2:end-1));
        end
    end
    if opt.OutTiming,
        timeStr= sprintf('%.1fs', et);
    end
    if opt.OutTiming && opt.OutSampling,
        infoStr= sprintf('  (%s for %s)', timeStr, smplStr);
    elseif opt.OutTiming,
        infoStr= sprintf('  (%s)', timeStr);
    elseif opt.OutSampling,
        infoStr= sprintf('  (on %s)', smplStr);
    else
        infoStr= '';
    end
    if opt.OutTrainloss,
        fprintf([opt.OutPrefix fmt opt.DisplayPlusMinus fmt ...
            ', [train: ' fmt opt.DisplayPlusMinus fmt ']' ...
            infoStr '\n'], [loss_mean; loss_std]);
    else
        fprintf([opt.OutPrefix fmt opt.DisplayPlusMinus fmt infoStr '\n'], ...
            loss_mean, loss_std);
    end
end
