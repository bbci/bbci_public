function ga= proc_grandAverage(varargin)
% PROC_GRANDAVERAGE -  calculates the grand average ERPs or ERD/ERS from given set of
% data.
%
%Usage:
%ga= proc_grandAverage(erps)
%ga= proc_grandAverage(erps, <OPT>)
%ga= proc_grandAverage(erp1, <erp2, ..., erpN>, <Prop1>, <Val1>, ...)
%
% IN   erps  -  cell array of erp structures
%      erpn  -  erp structure
%
% <OPT> - struct or property/value list of optional fields/properties:
%   Average   - If 'weighted', each ERP is weighted for the number of
%               epochs (giving less weight to ERPs made from a small number
%               of epochs). Default 'unweighted'
%   MustBeEqual - fields in the erp structs that must be equal across
%                 different structs, otherwise an error is issued
%                 (default {'fs','y','className'})
%   ShouldBeEqual - fields in the erp structs that should be equal across
%                   different structs, gives a warning otherwise
%                   (default {'yUnit'})
%Output:
% ga: Grand average
%

props = {   'Average'               'unweighted'                '!CHAR(weighted unweighted)';
            'MustBeEqual'           {'fs','y','className'}      'CHAR|CELL{CHAR}';
            'ShouldBeEqual'         {'yUnit'}                   'CHAR|CELL{CHAR}';
            };

if nargin==0,
  ga=props; return
end

%% Process input arguments
if iscell(varargin{1}),
  erps= varargin{1};
  opt= opt_proplistToStruct(varargin{2:end});
else
  iserp= ~cellfun(@ischar,varargin);
  nerps= find(iserp,1,'last');
  erps= varargin(1:nerps);
  opt= opt_proplistToStruct(varargin{nerps+1:end});
end


[opt, isdefault]= opt_setDefaults(opt, props);
opt_checkProplist(opt, props);

misc_checkType(erps,'CELL{STRUCT}');

%% Get common electrode set
clab= erps{1}.clab;
for ii= 2:length(erps),
  clab= intersect(clab, erps{ii}.clab);
end
if isempty(clab),
  error('intersection of channels is empty');
end

%% Define ga data field
datadim = unique(cellfun(@util_getDataDimension,erps));
if numel(datadim) > 1
  error('Datasets have different dimensionalities');
end

ga= rmfield(erps{1},intersect(fieldnames(erps{1}),'x'));
must_be_equal= intersect(opt.MustBeEqual, fieldnames(ga));
should_be_equal= intersect(opt.ShouldBeEqual, fieldnames(ga));

if datadim==1
  T= size(erps{1}.x, 1);
  E= size(erps{1}.x, 3);
  ci= util_chanind(erps{1}, clab);
  X= zeros([T length(ci) E length(erps)]);
else
  ci= util_chanind(erps{1}, clab);
  % Timefrequency data
  if ndims(erps{1}.x)==3   % no classes, erps are averages over single class
    F= size(erps{1}.x, 1);
    T= size(erps{1}.x, 2);
    X= zeros([F T length(ci) length(erps)]);
  elseif ndims(erps{1}.x)==4
    F= size(erps{1}.x, 1);
    T= size(erps{1}.x, 2);
    E= size(erps{1}.x, 4);
    X= zeros([F T length(ci) E length(erps)]);
  end
end

%% Store all erp data in X
for ii= 1:length(erps),
  for jj= 1:length(must_be_equal),
    fld= must_be_equal{jj};
    if ~isequal(getfield(ga,fld), getfield(erps{ii},fld)),
      error('inconsistency in field %s.', fld);
    end
  end
  for jj= 1:length(should_be_equal),
    fld= should_be_equal{jj};
    if ~isequal(getfield(ga,fld), getfield(erps{ii},fld)),
      warning('inconsistency in field %s.', fld);
    end
  end
  ci= util_chanind(erps{ii}, clab);
  if isfield(ga, 'V')
    iV(:,:,:,ii)= 1./erps{ii}.V;  
  end

  if datadim==1
    X(:,:,:,ii)= erps{ii}.x(:,ci,:);
  else
    if ndims(erps{1}.x)==3
      X(:,:,:,ii)= erps{ii}.x(:,:,ci);
    elseif ndims(erps{1}.x)==4
      X(:,:,:,:,ii)= erps{ii}.x(:,:,ci,:);
    end
  end
end

%% Perform averaging
if isfield(ga, 'yUnit') && strcmp(ga.yUnit, 'dB'),
  X= 10.^(X/10);
end
if isfield(ga, 'yUnit') && strcmp(ga.yUnit, 'r'),
  if strcmp(opt.Average, 'weighted'),
    % does it make sense to use weighting here?
    warning('weighted averaging not implemented for this case - ask Stefan');
  end
  ga.V = 1./sum(iV, 4);
  z = sum(atanh(X).*iV, 4).*ga.V;
  ga.x= tanh(z);
  ga.p = reshape(2*normal_cdf(-abs(z(:)), zeros(size(z(:))), sqrt(ga.V(:))), size(z));
else
  if strcmp(opt.Average, 'weighted'),
    if datadim==1
      ga.x= zeros([T length(ci) E]);
      for cc= 1:size(X, 3),  %% for each class
        nTotalTrials= 0;
        for vp= 1:size(X, 4),  %% average across subjects
          % TODO: sort out NaNs
          ga.x(:,:,cc)= ga.x(:,:,cc) + erps{vp}.N(cc)*X(:,:,cc,vp);
          nTotalTrials= nTotalTrials + erps{vp}.N(cc);
        end
        ga.x(:,:,cc)= ga.x(:,:,cc)/nTotalTrials;
      end
    else
      % Timefrequency data
      if ndims(erps{1}.x)==3   % only one class
        ga.x= zeros([F T length(ci)]);
        nTotalTrials= 0;
        for vp= 1:size(X, 4),  %% average across subjects
          % TODO: sort out NaNs
          ga.x = ga.x + erps{vp}.N*X(:,:,:,vp);
          nTotalTrials= nTotalTrials + erps{vp}.N;
        end
        ga.x = ga.x/nTotalTrials;

      elseif ndims(erps{1}.x)==4
        ga.x= zeros([F T length(ci) E]);
        for cc= 1:size(X, 4),  %% for each class
          nTotalTrials= 0;
          for vp= 1:size(X, 5),  %% average across subjects
            % TODO: sort out NaNs
            ga.x(:,:,:,cc)= ga.x(:,:,:,cc) + erps{vp}.N(cc)*X(:,:,:,cc,vp);
            nTotalTrials= nTotalTrials + erps{vp}.N(cc);
          end
          ga.x(:,:,:,cc)= ga.x(:,:,:,cc)/nTotalTrials;
        end
      end

    end
  else
    % Unweighted
    if datadim==1 || ndims(erps{1}.x)==3
      ga.x= nanmean(X, 4);
    else
      ga.x= nanmean(X, 5);
    end
  end
end
if isfield(ga, 'yUnit') && strcmp(ga.yUnit, 'dB'),
  ga.x= 10*log10(ga.x);
end

ga.clab= clab;
%% TODO should allow for weighting accoring to field N
%% (but this has to happen classwise)

ga.title= 'grand average';
ga.N= length(erps);
