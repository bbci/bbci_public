function H= plot_scalpEvolution(erp, mnt, ival, varargin)

props= {'PrintIval',    0,  'BOOL';
        'PlotChannel',  1,  'BOOL'};
props_scalpEvolutionPlusChannel= plot_scalpEvolutionPlusChannel;

if nargin==0,
  H= opt_catProps(props, props_scalpEvolutionPlusChannel);
  return
end

opt= opt_proplistToStruct(varargin{:});
[opt, isdefault]= opt_setDefaults(opt, props);
opt_checkProplist(opt, props, props_scalpEvolutionPlusChannel);

opt_scalpEvolutionPlusChannel= ...
    opt_substruct(opt, props_scalpEvolutionPlusChannel(:,1));

H= plot_scalpEvolutionPlusChannel(erp, mnt, [], ival, ...
                                  opt_scalpEvolutionPlusChannel);

if nargout<1,
  clear H
end
