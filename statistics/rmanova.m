function [p,t,stats,terms,arg] = rmanova(dat,varargin)
% RMANOVA - performs a conventional n-way analysis of variance (ANOVA)
% or a repeated-measures ANOVA. A conventional ANOVA assumes a
% between-subjects design (different groups), a RM ANOVA a within-subjects
% design (all subjects participated in all conditions).
%
%Usage:
% [p,t,stats,terms,arg] = rmanova(dat,<OPT>)
% [p,t,stats,terms,arg] = rmanova(dat,varnames,<OPT>)
%
%Arguments:
% DAT      -  N*F1*F2*F3*...*FN data matrix. 
%             First dimension (rows): refers to the subjects, ie each row 
%             contains the data of one subject. The second and successive 
%             dimensions contain the
%             factors, with the size of the dimension being the number of
%             levels of that factor. Example: for 13 subjects and the 
%             factors Speller with 3 levels (Hex,Cake,Center speller) and
%             Attention with 2 levels (overt, covert), the data matrix
%             would have a size of 13*3*2. The entry dat(5,2,1) refers to
%             the fifth subject for Cake Speller (2nd level of Speller) and
%             overt attention (1st level of Attention).
%
% OPT - struct or property/value list of optional properties:
% 'Varnames'   - CELL ARRAY of one or more factors (eg {'Speller'
%              'Attention'}). The order of the factors must correspond
%              to the order of the factors in the DAT matrix.
% 'Design' -  Test design. 'independent' performs a conventional ANOVA. 
%             If 'repeated-measures' (default), performs a
%             repeated-measures ANOVA. In the latter case, Subject is
%             included as a random (ie not fixed) effect.
% 'Display'  - if 'on' displays a table with the results (default 'on')
%
% Assumptions:
%   ANOVA   - homogeneity of variance: variances within each group are
%   equal
%   RM ANOVA - sphericity. Variation of population >difference< scores are
%   the same for all differences (for >2 levels of a factor).
%
% All other options are passed to the 'anovan' function.
%
%Returns:
% [p,t,stats,terms]     - 'help anovan' for details
% arg                   - arguments passed to anovan
%
% See also ANOVAN, PLOT_STATS.
%
% Note: If your experiment involves repeated-measures (your subject was run in all
% subconditions) you should use repeated-measures ANOVA (RM-ANOVA), because the
% assumption of independence of samples is violated. Furthermore, RM-ANOVA
% accounts for inter-subject variability and thus has more statistical
% power.

% Author(s): Matthias Treder 2011

varnames = [];
if nargin==2 
  varnames = varargin{1};
  varargin={};
elseif  nargin>1 && iscell(varargin{1})
  varnames = varargin{1};
  varargin = varargin(2:end);
end

props = {'Varnames',             varnames,          'CELL{CHAR}|CHAR';
         'Design',          'independent',          '!CHAR(repeated-measures independent)';
         'Display',                'on',            '!CHAR(on off)';
         'Alpha'                    .05,            '!DOUBLE[1]';
         'Model'                    'full',         '!CHAR(linear interaction full)|DOUBLE';
         'SSType'                   3,              '!CHAR(h)|INT';
         'Table'                    1,              '!BOOL';
         'Verbose'                  1,              '!BOOL';
         };
     
if nargin==0,
  p= props; return
end


opt= opt_proplistToStruct(varargin{:});
[opt,isdefault] = opt_setDefaults(opt, props);
opt_checkProplist(opt, props);
misc_checkType(dat,'!DOUBLE');

if ischar(opt.Varnames)
    opt.Varnames = {opt.Varnames};
end

ss = size(dat);
nsbj = ss(1);           % Number of subjects
level = ss(2:end);

%% Factors and levels
% Number of factors
if ~isempty(opt.Varnames)
  nfac = numel(opt.Varnames);
  if nfac ~= ndims(dat)-1
    error('Number of factors %d does not match factors in data %d',nfac,ndims(dat)-1)
  end
else
  nfac = ndims(dat)-1;
end
               
% If no factor names provided, use default names
if isempty(opt.Varnames)
  vn = num2cell(1:nfac);
  vn = cellfun(@num2str,vn,'UniformOutput',0);
  opt.Varnames = strcat('X',vn);
end


%% Check (RM) ANOVA assumptions // TODO


if strcmp(opt.Design,'independent')
  % Homogenity of variance
  % TODO
elseif strcmp(opt.Design,'repeated-measures')
  % Sphericity
end

%% ANOVA or rmANOVA
if opt.Verbose
  names = cell2mat(strcat(opt.Varnames,',')); names=names(1:end-1);
  fprintf('Performing a %d-way %s ANOVA with factors {%s} and %s = %d levels.\n',...
    nfac,opt.Design,names,str_vec2str(level,'%d','x'),prod(level))
end


if strcmp(opt.Design,'independent')
  % ANOVA model
  design = orthogonal_design(nsbj,level);

elseif strcmp(opt.Design,'repeated-measures')
  % Repeated measures ANOVA
  opt.Varnames = {'Subject' opt.Varnames{:}};  % Add subject as a factor
  if isfield(opt,'random')   % Add subject as random effect
    opt.Random = [1 opt.Random+1];
  else
    opt.Random = 1;
  end
  design = orthogonal_design(1,[nsbj level]);
  % Specify to-be-tested interactions by hand to omit Subject  
  model = double(flipud(dec2bin(0:2^(nfac+1)-1))-'0');
  model( model(:,1) & sum(model(:,2:end),2)>0 , :) = []; % Omit all interactions involving Subject
  maineffects = find(sum(model,2)==1);
  interactions = find(sum(model,2)>1);
  opt.Model = model([maineffects; interactions],:); % Bring in right order
else
  error('Unknown design ''%s''',opt.Design)
end

%% Perform ANOVA
arg = opt_structToProplist(rmfield(opt,{'Design','Table','Verbose','Alpha'}));

[p,t,stats,terms] = anovan(dat(:),design.anova,arg{:});

%% Provide output
if opt.Verbose
  fprintf('-------\nResults\n-------\n')
  % Find col indices
  F = find(ismember(t(1,:),'F','legacy'));
  p = find(ismember(t(1,:),'Prob>F','legacy'));
  for ii=2:size(terms,1)+1
    if t{ii,p}<opt.Alpha
      fprintf('''%s'' significant, F = %1.2f, p = %0.4f\n',...
        t{ii,1},t{ii,F},t{ii,p})
    else
      fprintf('''%s'' not significant, F = %1.2f, p = %0.4f\n',...
        t{ii,1},t{ii,F},t{ii,p})
    end
  end  
end


function d = orthogonal_design(nRows,nLevels)
% ORTHOGONAL_DESIGN - help function to create matrices with factor values
% assuming an orthogonal design (ie, there is data for each possible
% pairing of subconditions).
% Example: If you have the factors target/nontarget, and electrode 
% (Fz, Cz, Pz), and you measure the effect of these variables on 12
% subjects, you would get a 12 x 6 (=2*3) matrix wherein the rows represent 
% subjects, and the columns are:
% (1)target-Fz (2)nontarget-Fz (3)target-Cz (4)nontarget-Cz (5)target-Pz (6)nontarget-Pz
% The respective function call would be orthogonal_design(12,[2 3])
%
% Synopsis:
%   D = ORTHOGONAL_DESIGN(NROWS,NLEVELS)
%
% Arguments:
%   NROWS  : number of measurements of each factor (eg number of subjects)
%   NLEVELS: a vector with each field specifying the number of levels of
%     each factor
%
% Returns:
%   A struct with the following fields
%   .mat: a cell array with the corresponding matrices for each variable
%   (except the first)
%   .anova: vector notation of the factor matrices which you can feed
%   directly into anovan()
nFactors = numel(nLevels);
nCols = prod(nLevels);
d = struct('mat',zeros(nRows,nCols,nFactors),'anova',[],'anova_mat',[]);

% Construct first row and then copy n times
for jj=1:nFactors
  repLev = nCols / prod(nLevels(jj:end)); % Number of repeats of a levels

  if jj<nFactors   % Number of repeats of the sequence
    repSeq = prod(nLevels(jj+1:end));
  else repSeq=1;
  end

  row = [];
  for rr=1:repSeq
    for nn=1:nLevels(jj)
      row = [row repmat(nn,[1 repLev])];
    end
  end
  d.mat(1,:,jj)=row;
  %% Extend to all rows
  d.mat(:,:,jj) = repmat(row,[nRows 1]);
end

for jj=1:nFactors
  dd = d.mat(:,:,jj);
  d.anova{jj} = dd(:);
  d.anova_mat = [d.anova_mat dd(:)];
end
end


end


