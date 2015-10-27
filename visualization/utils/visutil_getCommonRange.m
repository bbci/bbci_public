function [CL] = visutil_getCommonRange(erp,ivals,varargin)
%VISUTIL_GETMAXRANGE - get maximum CLim range for several scalp plots of
%data in erp defined by ivals
%
%Synopsis:
% CLIM= visutil_getMaxRange(erp, ivals)
%
%Input:
% erp: eeg data
% ERP: struct of epoched EEG data.
% IVAL: time intervals for which scalp topography are to be plotted.

% irene, 10/2015
props= {
        'Class',     [],   '';
        'CLim',                 'sym',             'CHAR|DOUBLE[2]'};
    
if nargin==0,
  H= opt_catProps(props, props_scalpOutline); return
end

opt= opt_proplistToStruct(varargin{:});
[opt, isdefault]= opt_setDefaults(opt, props);
nIvals=size(ivals,1);

for ii= 1:nIvals,
    if any(isnan(ivals(ii,:))),
      continue;
    end
    eee= erp;
    if nargin>=2 && ~isempty(ivals(ii,:)) && ~sum(any(isnan(ivals))),
         eee= proc_selectIval(eee, ivals(ii,:), 'IvalPolicy','minimal');
    end
    if ~isempty(opt.Class),
         eee= proc_selectClasses(eee, opt.Class);
    end
    if max(sum(eee.y,2))>1,
        eee= proc_average(eee);
    end
    eee.x= mean(eee.x,1);
    min_max(ii,1)=min(min(eee.x));
    min_max(ii,2)=max(max(eee.x));
end

if isequal(opt.CLim, 'sym'),
  zgMax= max(abs(min_max(:,2)));
  CL= [-zgMax zgMax];
elseif isequal(opt.CLim, 'range'),
  CL= [min(min_max(:,1)) max(min_max(:,2))];
elseif isequal(opt.CLim, '0tomax'),
  CL= [0.0001*diff([min(min_max(:,1)) max(min_max(:,2))]) max(min_max(:,2))];
elseif isequal(opt.CLim, 'minto0'),
  CL= [min(min_max(:,1)) 0.0001*diff([min(min_max(:,1)) max(min_max(:,2))])];
elseif isequal(opt.CLim, 'zerotomax'),
  CL= [0 max(min_max(:,2))];
elseif isequal(opt.CLim, 'mintozero'),
  CL= [min(min_max(:,1)) 0];
end
if diff(CL)==0, CL(2)= CL(2)+eps; end
end