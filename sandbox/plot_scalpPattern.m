function H= plot_scalpPattern(erp, mnt, ival, varargin)

props= {'Class',     [],   '';
        'YUnit',     '',   'CHAR';
        'Contour',   0,    'DOUBLE'};
props_scalp= plot_scalp;

if nargin==0,
  H= opt_catProps(props, props_scalp);
  return
end


opt= opt_proplistToStruct(varargin{:});
opt= opt_setDefaults(opt, props);
opt_checkProplist(opt, props, props_scalp);

%
% ...
%

opt_scalp= opt_substruct(opt, props_scalp(:,1));
H= plot_scalp(mnt, erp, opt_scalp);
