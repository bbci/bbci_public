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
%  procutil_getClabForLaplacian, proc_linearDerivation

%        Benjamin Blankertz
% 07-2012 Johannes Hoehne - Updated documentation and parameter naming


props= {'clab'                         '*'          '!CHAR';
        'IgnoreCLab'                   {'E*'}       'CHAR|CELL{CHAR}'
        'CopyCLab'                     {'E*'}       'CHAR|CELL{CHAR}'
        'requireCompleteNeighborhood'  1            '!BOOL' 
        'requireCompleteOutput'        0            '!BOOL' 
        'appendix'                     ' lap'       'CHAR' 
        'verbose'                      0            'BOOL'
        'GridFcn'                      @util_gridForLaplacian 'FUNC'
        'FilterType'                   'small'      'CHAR(small large horizontal vertical bip_to_anterior bip_to_posterior bip_to_left bip_to_right diagonal diagonal_small)'
        };

if nargin==0,
  varargout{1} = props; 
  return
end

dat = misc_history(dat);
opt= opt_proplistToStruct(varargin{:});
[opt, isdefault]= opt_setDefaults(opt, props);
opt_checkProplist(opt, props);

misc_checkType(dat, 'STRUCT(clab)');

if ~iscell(opt.IgnoreCLab),
  opt.IgnoreCLab= {opt.IgnoreCLab};
end

laplace= [];
laplace.grid= opt.GridFcn();
if isnumeric(opt.FilterType),
  laplace.filter= opt.FilterType;
else
  laplace.filter= procutil_lapGetLaplacianFilter(opt.FilterType);
end

if ~isstruct(dat),
  dat= struct('clab',{dat});
end

rc= util_chanind(dat, {'not', opt.IgnoreCLab{:}});
nOrigChans= length(dat.clab);
pos= zeros(2, nOrigChans);
for ic= 1:nOrigChans,
  pos(:,ic)= procutil_lapGetCoordinates(dat.clab{ic}, laplace.grid);
end
pos(:,setdiff(1:nOrigChans,rc,'legacy'))= inf;

idx_tbf= util_chanind(dat, opt.clab);
W= zeros(length(dat.clab), length(idx_tbf));
clab = [];
lc= 0;
for ci= 1:length(idx_tbf),
  cc= idx_tbf(ci);
  refChans= [];
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
W= W(:,1:lc);

if isfield(dat, 'x'),
  out= proc_linearDerivation(dat, W, 'clab', strcat(clab, opt.appendix));
  if ~isempty(opt.CopyCLab),
    idx= util_chanind(dat, opt.CopyCLab);
    if ~isempty(idx),
      out.x= cat(2, out.x, dat.x(:,idx,:));
      out.clab= cat(2, out.clab, dat.clab(idx));
    end
  end
  varargout= {out, W};
else
  varargout= {W};
end
