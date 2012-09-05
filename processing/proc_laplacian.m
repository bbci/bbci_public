function varargout= proc_laplacian(dat, varargin)
%PROC_LAPLACIAN - Apply spatial Laplacian filter to signals
%
%Synopsis:
% [DAT_LAP, LAP_W]= proc_laplacian(DAT, <OPT>)
%
%Arguments:
% DAT: data structure of continuous or epoched data
% OPT: struct or proerty/value list of optional properties:
%  .filterType    - {small, large, horizontal, vertical, diagonal, eight},
%                     default 'small'
%  .clab - channels that are to be obtained, default '*'.
%  .ignoreClab: labels of channels to be ignored, default {'E*'}.
%  .requireCompleteNeighborhood
%  .requireCompleteOutput
%  .verbose
%
%Returns:
%  DAT_LAP: updated data structure
%  LAP_W:   filter matrix that can be used, e.g. in proc_linearDerivation
%
%See also:
%  getClabForLaplacian, proc_linearDerivation

%        Benjamin Blankertz
% 07-2012 Johannes Hoehne - Updated documentation and parameter naming

props= {'clab'          '*'         '!CHAR';
        'ignoreClab'    {'E*'}      'CHAR|CELL{CHAR}';
        'copyClab'      {'E*'}      'CHAR|CELL{CHAR}';
        'grid'          'grid_128'  'CHAR';
        'filterType'    'small'     'CHAR(small large horizontal vertical diagonal eight)';
        'requireCompleteNeighborhood'    1      '!BOOL';
        'requireCompleteOutput'          0      '!BOOL';
        'appendix'      ' lap'      'CHAR';
        'verbose'       0           'BOOL';
        };

if nargin==0,
  varargout{1} = props; 
  return
end

dat = misc_history(dat);
opt= opt_proplistToStruct(varargin{:});
[opt, isdefault]= opt_setDefaults(opt, props);
% opt_checkProplist(opt, props);

misc_checkType(dat, 'STRUCT(x clab)');

if ~iscell(opt.ignoreClab),
  opt.ignoreClab= {opt.ignoreClab};
end

laplace= [];
laplace.grid= getGrid(opt.grid);
if isnumeric(opt.filterType),
  laplace.filter= opt.filterType;
elseif isequal(opt.filterType, 'flexi')
  laplace.filter= [];
  % for standard positions C3, CP5, etc
  laplace.filter1= getLaplaceFilter('small');
  % for extended positions CFC3, PCP1, etc
  laplace.filter2= getLaplaceFilter('diagonalSmall');
else
  laplace.filter= getLaplaceFilter(opt.filterType);
end

if ~isstruct(dat),
  dat= struct('clab',{dat});
end

rc= util_chanind(dat, {'not', opt.ignoreClab{:}});
nOrigChans= length(dat.clab);
pos= zeros(2, nOrigChans);
for ic= 1:nOrigChans,
  pos(:,ic)= getCoordinates(dat.clab{ic}, laplace.grid);
end
pos(:,setdiff(1:nOrigChans,rc))= inf;

idx_tbf= util_chanind(dat, opt.clab);
W= zeros(length(dat.clab), length(idx_tbf));
clab = [];
lc= 0;
filter_tmp = laplace.filter;
for ci= 1:length(idx_tbf),
  cc= idx_tbf(ci);
  refChans= [];
  if isequal(opt.filterType, 'flexi'),
    clab_tmp= strrep(dat.clab{cc}, 'z','0');
    if sum(isletter(clab_tmp))<3,
      laplace.filter= laplace.filter1;
    else
      laplace.filter= laplace.filter2;
    end
  end
  if isequal(opt.filterType, 'eleven'),
    if isnan(mod(str2double(dat.clab{cc}(end)),2))
      warning('asymmetric filter type ''eleven'' ignores central channels');
      continue;
    end
  end
  if size(filter_tmp,3) > 1
    if isequal(dat.clab{cc}(end),'z')
      laplace.filter = filter_tmp(:,:,2);
    elseif mod(str2double(dat.clab{cc}(end)),2)
      laplace.filter = filter_tmp(:,:,1);
    else
      laplace.filter = filter_tmp(:,:,end);
    end
  end
  nRefs= size(laplace.filter,2);
  for ir= 1:nRefs,
    ri= find( pos(1,:)==pos(1,cc)+laplace.filter(1,ir) & ...
      pos(2,:)==pos(2,cc)+laplace.filter(2,ir) );
    refChans= [refChans ri];
  end
  if length(refChans)==nRefs | ~opt.requireCompleteNeighborhood,
    lc= lc+1;
    W(cc,lc)= 1;
    if ~isempty(refChans),
      W(refChans,lc)= -1/length(refChans);
    end
    clab= [clab, dat.clab(cc)];
    if opt.verbose,
      fprintf('%s: ref''ed to: %s\n', ...
        dat.clab{cc}, str_vec2str(dat.clab(refChans)));
    end
  elseif opt.requireCompleteOutput,
    error('channel %s has incomplete neighborhood', dat.clab{cc});
  end
end
clear filter_tmp
W= W(:,1:lc);

if isfield(dat, 'x'),
  out= proc_linearDerivation(dat, W, 'clab', strcat(clab, opt.appendix));
  if ~isempty(opt.copyClab),
    out= proc_copyChannels(out, dat, opt.copyClab);
  end
  varargout= {out, W};
else
  varargout= {W};
end



function pos= getCoordinates(lab, grid)

nRows= size(grid,1);
%w_cm= warning('query', 'bci:missing_channels');
%warning('off', 'bci:missing_channels');
ii= util_chanind(grid, lab);
%warning(w_cm);
if isempty(ii),
  pos= [NaN; NaN];
else
  xc= 1+floor((ii-1)/nRows);
  yc= ii-(xc-1)*nRows;
  xc= 2*xc - isequal(grid{yc,1},'<');
  pos= [xc; yc];
end



function filt= getLaplaceFilter(filterType)

switch lower(filterType),
  case 'sixnew'
    filt = [-4 0; -2 0; 0 -2; 0 2; 2 0; 4 0]';
  case 'eightnew'    
    filt = [-4 0; -2 -2; -2 0; -2 2; 2 -2; 2 0; 2 2; 4 0]';
  case 'small',
    filt= [0 -2; 2 0; 0 2; -2 0]';
  case 'large',
    filt(:,:,1) = [-2 0; 0 -2; 0 2; 2 0; 4 0; 8 0]';
    filt(:,:,2) = [-4 0; -2 0; 0 -2; 0 2; 2 0; 4 0]';
    filt(:,:,3) = [-8 0; -4 0; -2 0; 0 -2; 0 2; 2 0]';  
  case 'horizontal',
    filt= [-2 0; 2 0]';
  case 'vertical',
    filt= [0 -2; 0 2]';
  case 'bipToAnterior';
    filt= [0 -2]';
  case 'bipToPosterior';
    filt= [0 2]';
  case 'bipToLeft';
    filt= [-2 0]';
  case 'bipToRight';
    filt= [2 0]';
  case 'diagonal',
    filt= [-2 -2; 2 -2; 2 2; -2 2]';
  case 'diagonalSmall',
    filt= [-1 -1; 1 -1; 1 1; -1 1]';
  case 'six',
    filt= [-2 0; -1 -1; 1 -1; 2 0; 1 1; -1 1]';
  case 'eightsparse',
    filt= [-2 0; -2 -2; 0 -2; 2 -2; 2 0; 2 2; 0 2; -2 2]';
  case 'eight',
    filt= [-2 0; -1 -1; 0 -2; 1 -1; 2 0; 1 1; 0 2; -1 1]';
  case 'ten'
    filt= [-4 0; -2 -2; -2 0; -2 2; 0 -2; 0 2; 2 -2; 2 0; 2 2; 4 0]';
  case 'elevenToAnterior'
    % eleven unsymmetric neighbors for channel in the left emisphere
    % (neigbors more going to the left)
    filt(:,:,1) = [-4 0; -4 2; -2 -2; -2 0; -2 2; -2 4; 0 -2; 0 2; 0 4; 2 0; 2 2]';
    % eleven unsymmetric neighbors for channel in the right emisphere
    % (neigbors more going to the right)
    filt(:,:,2) = [-2 0; -2 2; 0 -2; 0 2; 0 4; 2 -2; 2 0; 2 2; 2 4; 4 0; 4 2]';
  case 'eleven'
    filt(:,:,1) = [-4 -2; -4 0; -4 2; -2 -2; -2 0; -2 2; 0 -2; 0 2; 2 -2; 2 0; 2 2]';
    filt(:,:,2) = [-2 -2; -2 0; -2 2; 0 -2; 0 2; 2 -2; 2 0; 2 2; 4 -2; 4 0; 4 2]';
  case 'twelve'
    filt = [-2 0; -2 -2; 0 -2; 2 -2; 2 0; 2 2; 0 2; -2 2; -1 -1; 1 -1; 1 1; -1 1]';  
  case 'eighteen',
    filt= [-2 2; 0 2; 2 2; -3 1; -1 1; 1 1; 3 1; -4 0; -2 0; 2 0; 4 0; -3 -1; -1 -1; 1 -1; 3 -1; -2 -2; 0 -2; 2 -2]';
  case 'twentytwo'
    filt = [-1 3; 1 3; -2 2; 0 2; 2 2; -3 1; -1 1; 1 1; 3 1; -4 0; -2 0; 2 0; 4 0; -3 -1; -1 -1; 1 -1; 3 -1; -2 -2; 0 -2; 2 -2; -1 -3; 1 -3]';
  otherwise
    error('unknown filter matrix');
end

