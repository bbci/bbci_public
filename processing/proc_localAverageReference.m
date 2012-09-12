function [out, W]= proc_localAverageReference(dat, mnt, varargin)
%PROC_LOCALAVERAGEREFERENCE - Rereference all channels to local average
%
%Synopsis:
%  [DAT, W]= proc_localAverageReference(DAT, MNT, RADIUS)
%  [DAT, W]= proc_localAverageReference(DAT, MNT, <OPT>)
%
%Arguments:
%  DAT: Data structure of continuous or epoched data
%  MNT: Electrode montage, see getElectrodePositions
%  RADIUS: see OPT.radius
%  OPT: struct or property/value list of optional properties:
%    .radius: For a radius of 0.8, the neighborhood of Cz extends from
%      C3 to C4 and from Fz to Pz. For a radius of 0.4 it extends from
%      C1 to C2 and from FCz to CPz. Default 0.8.
%    .clab: Labels of channels which are to be retrieved.
%    .median: If true, reference is calculated as median across
%      neighboring channels, instead of mean. Default 0.
%    .verbose: If true, text output shows the rereferencing
%
%Returns:
%  DAT: updated data structure
%  W:   filter matrix that can be used, e.g. in proc_linearDerivation
%       (before you need to exclude the same channels
%
%Description:
% Rereference signals to local average, i.e. to the average of all
% electrodes within a given radius.
%
%SEE:
%  proc_commonAverageReference, proc_laplacian, getElectrodePositions

% Author: Benjamin Blankertz
dat = misc_history(dat);

props= { 'radius'       0.8     'DOUBLE[1]'
         'clab'         '*'     'CHAR|CELL{CHAR}'
         'ignore_clab'  {'E*'}  'CHAR|CELL{CHAR}'
         'median'       0       'BOOL'
         'verbose'      0       'BOOL'};

if nargin==0,
  out = props; return
end

misc_checkType(dat, 'STRUCT(x clab)'); 
if length(varargin)==1 & isnumeric(varargin{1}),
  opt= struct('radius', varargin{1});
else
  opt= opt_proplistToStruct(varargin{:});
end
[opt, isdefault]= opt_setDefaults(opt, props);
opt_checkProplist(opt, props);

if ~iscell(opt.ignore_clab),
  opt.ignore_clab= {opt.ignore_clab};
end

mnt= mnt_adaptMontage(mnt, dat);
if ~isequal(mnt.clab, dat.clab),
  error('channel mismatch');
end
rc= util_chanind(dat, {'not', opt.ignore_clab{:}});
idx_tbf= util_chanind(dat, opt.clab);
out= proc_selectChannels(dat, opt.clab);
W= zeros(length(dat.clab), length(idx_tbf));
for ci= 1:length(idx_tbf),
  cc= idx_tbf(ci);
  pos= repmat(mnt.pos_3d(:,cc), [1 length(rc)]);
  dist= sqrt(sum( (mnt.pos_3d(:,rc)-pos).^2) );
  iRef= find(dist>0 & dist<opt.radius);
  if opt.verbose,
    fprintf('%s: ref''ed to: %s\n', dat.clab{cc}, str_vec2str(dat.clab(rc(iRef))));
  end
  W(cc,ci)= 1;
  if ~isempty(iRef),
    if opt.median,
      lar= median(dat.x(:,rc(iRef),:), 2);
    else
      lar= mean(dat.x(:,rc(iRef),:), 2);
    end
    out.x(:,ci,:)= dat.x(:,cc,:) - lar;
    out.clab{ci}= [dat.clab{cc} ' lar'];
    W(rc(iRef),ci)= -1/length(iRef);
  end
end
