function fig_publish(fig_state)
%function out= fig_publish(fig_state, varargin)

%props= {'KeepMinimized'   0   '!BOOL'
%       };
% 
%if nargin==0,
%  out= props;
%end
%opt= opt_proplistToStruct(varargin{:});
%opt= opt_setDefaults(opt, props, 1);
misc_checkType(fig_state, 'STRUCT(WasVisible)');

% fig_state.WasVisible==[] means, the figure was newly created by fig_set
if isempty(fig_state.WasVisible) || strcmp(fig_state.WasVisible,'on'),
  set(gcf, 'Visible','on');
end
drawnow;
