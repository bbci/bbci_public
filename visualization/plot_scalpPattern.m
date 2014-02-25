function [H, Ctour]= plot_scalpPattern(erp, mnt, ival, varargin)
%PLOT_SCALPPATTERN - Display average trials as scalp topography
%
%Usage:
% H= plot_scalpPattern(ERP, MNT, IVAL, <OPTS>)
%
%Input:
% ERP: struct of epoched EEG data.
% MNT: struct defining an electrode montage
% IVAL: time interval for which scalp topography is to be plotted.
% OPTS: struct or property/value list of optional fields/properties:
%  .Class - specifies the Class (name or index) of which the topogaphy
%           is to be plotted. For displaying topographies of several Classes
%           use plot_scalpPatterns.
%The opts struct is passed to plot_scalp.
%
%Output:
% H:     Handle to several graphical objects.
% Ctour: Struct of contour information
%
%See also plot_scalpPatterns, plot_scalpEvolution, plot_scalp

props= {'Class',     [],   '';
        'Contour',   0,    'DOUBLE';
        'YUnit',     '',   'CHAR'
        };
    
props_scalp= plot_scalp;

if nargin==0,
  H= opt_catProps(props, props_scalp);
  return
end

opt= opt_proplistToStruct(varargin{:});
[opt, isdefault]= opt_setDefaults(opt, props);
opt_checkProplist(opt, props, props_scalp);

opt_scalp= opt_substruct(opt, props_scalp(:,1));

if isdefault.YUnit && isfield(erp, 'yUnit'),
  opt.YUnit= ['[' erp.yUnit ']'];
elseif isdefault.YUnit && isfield(erp, 'cnt_info') && ...
        isfield(erp.cnt_info, 'yUnit'),
  opt.YUnit= ['[' erp.cnt_info.yUnit ']'];
end

eee= erp;
if nargin>=3 && ~isempty(ival) && ~any(isnan(ival)),
  eee= proc_selectIval(eee, ival, 'IvalPolicy','minimal');
end
if ~isempty(opt.Class),
  eee= proc_selectClasses(eee, opt.Class);
end
if max(sum(eee.y,2))>1,
  eee= proc_average(eee);
end
if size(eee.x,3)>1,
  error('For plotting topographies of multiple Classes use ''plot_scalpPatterns''');
end
eee.x= mean(eee.x,1);
head= mnt_adaptMontage(mnt, eee);
eee= proc_selectChannels(eee, head.clab(find(~isnan(head.x))));
head= mnt_adaptMontage(mnt, eee);

if opt.Contour,
    [H, Ctour]= plot_scalp(head, squeeze(eee.x), opt_scalp);
else
    H = plot_scalp(head, squeeze(eee.x), opt_scalp);
end

if isfield(opt, 'sublabel'),
  yLim= get(gca, 'yLim');
  H.sublabel= text(mean(xlim), yLim(1)-0.04*diff(yLim), opt.sublabel);
  set(H.sublabel, 'verticalAli','top', 'horizontalAli','center', ...
                  'Visible','on');
end

if nargout<2,
  clear Ctour;
end
if nargout<1,
  clear H;
end
