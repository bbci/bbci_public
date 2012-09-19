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
% 09-2012 stefan.haufe@tu-berlin.de

% TODO: avoid making a full copy of the data into array X

props = {   'Average'               'arithmetic'                '!CHAR(Nweighted INVVARweighted arithmetic)';
            'MustBeEqual'           {'fs','y','className'}      'CHAR|CELL{CHAR}';
            'ShouldBeEqual'         {'yUnit'}                   'CHAR|CELL{CHAR}';
            'Stats'                 0                           '!BOOL'};

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
%   if isfield(ga, 'V')
%     iV(:,:,:,ii)= 1./erps{ii}.V;  
%   end

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

if strcmp(opt.Average, 'INVVARweighted') && ~isfield(ga, 'sem')
   warning('No SEM given to perform inverse variance weighted averaging. Performing arithmetic (unweighted) averaging instead.') 
   opt.Average = 'arithmetic';
end

if opt.Stats && ~isfield(ga, 'sem')
   warning('No SEM given to perform statistical analysis.') 
   opt.Stats = 0;
end

%% Pre-transformation to make the data (more) Gaussian for some known statistics
if isfield(ga, 'yUnit') 
  switch ga.yUnit
    case 'dB'
      X= 10.^(X/10); % actually, staying on dB scale would not be that bad
    case 'r',
      X = atanh(X);
%       ga.p = reshape(2*normal_cdf(-abs(z(:)), zeros(size(z(:))), sqrt(ga.V(:))), size(z));
    case 'r^2',
      X = atanh(sqrt(X));
    case 'sgn r^2',
      X = atanh(sqrt(abs(X)).*sign(X));
    case 'auc'
      X = X - 0.5;
  end
end

switch opt.Average
  case 'Nweighted',
  if datadim==1
    ga.x= zeros([T length(ci) E]);
    for cc= 1:size(X, 3),  %% for each class
      nTotalTrials= 0;
      siV = 0;
      for vp= 1:size(X, 4),  %% average across subjects
        % TODO: sort out NaNs
        ga.x(:,:,cc)= ga.x(:,:,cc) + erps{vp}.N(cc)*X(:,:,cc,vp);
        nTotalTrials= nTotalTrials + erps{vp}.N(cc);
        siV = siV + erps{vp}.sem(:, :, cc).^2;
      end
      ga.x(:,:,cc)= ga.x(:,:,cc)/nTotalTrials;
      if opt.Stats
        ga.sem(:, :, cc) = sqrt(1./siV);
      end
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
  case 'INVVARweighted',        
    if datadim==1
    ga.x= zeros([T length(ci) E]);
    for cc= 1:size(X, 3),  %% for each class
      siV= 0;
      for vp= 1:size(X, 4),  %% average across subjects
        % TODO: sort out NaNs
        iV = 1./erps{vp}.sem(:, :, cc).^2;
        ga.x(:,:,cc)= ga.x(:,:,cc) + X(:,:,cc,vp).*iV;
        siV = siV + iV;
      end
      ga.x(:,:,cc)= ga.x(:,:,cc)./siV;
      if opt.Stats
        ga.sem(:, :, cc) = sqrt(1./siV);
      end
    end
  else
    % Timefrequency data
    if ndims(erps{1}.x)==3   % only one class
      ga.x= zeros([F T length(ci)]);
      siV= 0;
      for vp= 1:size(X, 4),  %% average across subjects
        % TODO: sort out NaNs
        iV = 1./erps{vp}.sem.^2;
        ga.x = ga.x + X(:,:,:,vp).*iV;
        siV = siV + iV;
      end
      ga.x = ga.x./siV;
      if opt.Stats
        ga.sem = sqrt(1./siV);
      end
    elseif ndims(erps{1}.x)==4
      ga.x= zeros([F T length(ci) E]);
      for cc= 1:size(X, 4),  %% for each class
        siV= 0;
        for vp= 1:size(X, 5),  %% average across subjects
          % TODO: sort out NaNs
          iV = 1./erps{vp}.sem(:, :, :, cc).^2;
          ga.x(:,:,:,cc)= ga.x(:,:,:,cc) + X(:,:,:,cc,vp).*iV;
          siV = siV + iV;
        end
        ga.x(:,:,:,cc)= ga.x(:,:,:,cc)./siV;
        if opt.Stats
          ga.sem(:, :, :, cc) = sqrt(1./siV);
        end
      end
    end
  end
  otherwise    
  % arithmetic
  if datadim==1 || ndims(erps{1}.x)==3
    ga.x= nanmean(X, 4);
  else
    ga.x= nanmean(X, 5);
  end
end

if opt.Stats
  switch opt.Average
      ga.p = reshape(2*normal_cdf(-abs(ga.x(:)), zeros(size(ga.x(:))), ga.sem(:), size(ga.x)));
      ga.sgnlogp = -log10(ga.p).*sign(ga.x);      
  end
end
  
%% Post-transformation to bring the GA data to the original unit
if isfield(ga, 'yUnit') 
  switch ga.yUnit
    case 'dB'
      ga.x= 10*log10(ga.x);
    case 'r',
      ga.x= tanh(ga.x);
    case 'r^2',
      ga.x= tanh(ga.x).^2;
    case 'sgn r^2',
      ga.x= tanh(ga.x).*abs(tanh(ga.x));
    case 'auc'
      X = min(max(X + 0.5, 0), 1);
  end
end

ga.clab= clab;

ga.title= 'grand average';
ga.N= length(erps);
