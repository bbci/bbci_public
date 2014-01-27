function [requ_clab, W, neighbor_clab]= procutil_getClabForLaplacian(dat, varargin)
%GETCLABFORLAPLACIAN - Get channels which are required for Laplacian filtering
%
%Synopsis:
%   CLAB= procutil_getClabForLaplacian(DAT, <OPT>)
%   CLAB= procutil_getClabForLaplacian(DAT, CLAB, <OPT>)
%
%Arguments:
%   DAT:    STRUCT   - Continuous or epoched data, or directly the full
%                      channel set from which the clabs for laplacian should 
%                      be extracted
%   CLAB:   CELL     - Names of channels that should be filtered by 
%                      proc_laplacian. Accepts wildcards.
%   OPT: 	PROPLIST - struct or property/value list of optional properties:
%     'FilterType': CHAR (default 'small') - Name of the type of Laplace
%                      filter that should be used. Simply add your filter
%                      to the subfunction 'getLaplaceFilter'.
%     'CLab': CELL     - Equal to CLAB as a second parameter.
%     'IgnoreCLab': CELL (default {'E*'}) - Names of the channels that are
%                      to be left out of the calculation.
%     'GridFcn': FUNC
%     'RequireCompleteNeighborhood: BOOL (default 1) - Enforce that a
%                      Laplace channel can only be returned if all the
%                      necessary neighbors are available.
%
%Returns:
%   REQU_CLAB:         cell array of channel labels, necessary for the
%                      given Laplace channels
%   W:                 filter matrix that can be used, e.g. in 
%                      proc_linearDerivation, to calculate the Laplace
%                      channels
%   NEIGHBOR_CLAB:     Channels around the Laplace channels that are used
%                      for referencing
%
%Examples:
%   procutil_getClabForLaplacian(dat, {'C3', 'C4'});
%   procutil_getClabForLaplacian(dat, 'FilterType', 'large', 'CLab', {'C3', 'C4'});

%See:
% proc_laplacian
%
% Benjamin Blankertz
% Martijn Schreuder 06/12 - Updated the help documentation


props= {'CLab'                         '*'                    'CHAR|CELL{CHAR}'
        'IgnoreCLab'                   {'E*'}                 'CHAR|CELL{CHAR}'
        'GridFcn'                      @util_gridForLaplacian 'FUNC'
        'FilterType'                   'small'                'CHAR(small large horizontal vertical bip_to_anterior bip_to_posterior bip_to_left bip_to_right diagonal diagonal_small)'
        'RequireCompleteNeighborhood'  1                      'BOOL'};

if mod(nargin,2)==0,
  misc_checkType(varargin{1}, 'CHAR|CELL{CHAR}', 'CLAB');
  opt= opt_proplistToStruct(varargin{2:end});
  opt.CLab= varargin{1};
else
  opt= opt_proplistToStruct(varargin{:});
end

[opt,isdefault] = opt_setDefaults(opt, props);
opt_checkProplist(opt, props);
misc_checkType(dat, 'CELL{CHAR}|STRUCT(clab)');
tcstate= bbci_typechecking('off');

if ~iscell(opt.IgnoreCLab),
  opt.IgnoreCLab= {opt.IgnoreCLab};
end

if isstruct(dat)
  clab= dat.clab;
else
  clab= dat;
end
  
laplace= [];
laplace.grid= opt.GridFcn();
laplace.filter= procutil_lapGetLaplacianFilter(opt.FilterType);

rc= util_chanind(clab, cat(2, {'not'}, opt.IgnoreCLab));
nOrigChans= length(clab);
pos= zeros(2, nOrigChans);
for ic= 1:nOrigChans,
  pos(:,ic)= procutil_lapGetCoordinates(clab{ic}, laplace.grid);
end
pos(:,setdiff(1:nOrigChans,rc,'legacy'))= inf;

idx_tbf= util_chanind(clab, opt.CLab);
W= zeros(length(clab), length(idx_tbf));
lc= 0;
requ_clab= {};
neighbor_clab= cell(length(idx_tbf), 1);
for ci= 1:length(idx_tbf),
  cc= idx_tbf(ci);
  refChans= [];  
  nRefs= size(laplace.filter,2);
  for ir= 1:nRefs,
    ri= find( pos(1,:)==pos(1,cc)+laplace.filter(1,ir) & ...
      pos(2,:)==pos(2,cc)+laplace.filter(2,ir) );
    refChans= [refChans ri];
  end
  if length(refChans)==nRefs | ~opt.RequireCompleteNeighborhood,
    lc= lc+1;
    W(cc,lc)= 1;
    if ~isempty(refChans),
      W(refChans,lc)= -1/length(refChans);
    end
    requ_clab= unique(cat(2, requ_clab, clab([cc refChans])),'legacy');
    neighbor_clab{ci}= clab(refChans);
  end
end
W= W(util_chanind(clab, requ_clab),:);

bbci_typechecking(tcstate);
