function jvm_restoreFig(jvm, varargin)

% opt= propertylist2struct(varargin{:});
opt = opt_proplistToStruct(varargin{:});
opt= opt_setDefaults(opt, {'fig_hidden', 0});

if ~isempty(jvm) && ~opt.fig_hidden,
  set(jvm.fig, 'Visible',jvm.visible);
end
