function jvm_restoreFig(jvm, varargin)

opt = opt_proplistToStruct(varargin{:});
opt= opt_setDefaults(opt, {'FigHidden', 0});

if ~isempty(jvm) && ~opt.FigHidden
  set(jvm.fig, 'Visible',jvm.visible);
end
