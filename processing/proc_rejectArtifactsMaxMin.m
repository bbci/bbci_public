function [epo, iArte]= proc_rejectArtifactsMaxMin(epo, threshold, varargin)
%PROC_REJECTARTIFACTSMAXMIN - Reject epochs according to max-min criterion
%
%This function rejects epochs within which the difference of maximum
%minus minum value exceeds a given threshold. Optionally, the criterion
%can be evaluated on a subset of channels and on a subinterval.
%
%Synopsis:
%  [EPO, IARTE]= proc_rejectArtifactsMaxMin(EPO, THRESHOLD, <OPT>)
%
%Arguments:
%  EPO - Data structure of epoched data, see CntToEpo
%  THRESHOLD - Threshold that evokes rejection, when the difference of
%     maximum minus minimum value within an epoch exceeds this value.
%     for THRESHOLD=0 the function returns without rejection.
%  OPT - Property/value list or struct of optional properties:
%    'Clab': [Cell array of Strings]: Channels on which the criterion
%            is evaluated
%    'Ival': [START END]: Time interval within the epoch on which the
%            criterion is evaluated
%    'AlLChannels': When true, epochs are rejected only if the threshold 
%            is exceeded for all channels. Otherwise, one channel for  
%            which the threshold is exceeded suffices to reject the epoch.
%    'verbose': When true, an output informs
%            about the number of rejected trials (if any).
%
%Returns:
%  EPO - Data structure where artifact epochs have been eliminited.
%  IARTE - Indices of rejected epochs

% 05-2011 Benjamin Blankertz
% 09-2012 toolbox conformity stefan.haufe@tu-berlin.de
% 

props= {'Clab'          []          'CHAR';
        'Ival'          ''          'DOUBLE[2]';
        'AllChannels'   0           'BOOL';
	'Verbose'       0           'BOOL'
        };

if nargin==0,
  out = props; return
end

misc_checkType(epo,  'STRUCT(x clab)');
misc_checkType(threshold, 'DOUBLE[1]');
epo = misc_history(epo);

opt= opt_proplistToStruct(varargin{:});

[opt, isdefault]= opt_setDefaults(opt, props);



if threshold<=0,
  iArte= [];
  return;
end

epo_crit= epo;
if ~isempty(opt.Ival),
  epo_crit= proc_selectIval(epo_crit, opt.Ival);
end

if ~isempty(opt.Clab) && ~isequal(opt.Clab,'*'),
  epo_crit= proc_selectChannels(epo_crit, opt.Clab);
end

sz= size(epo_crit.x);
epo_crit.x= reshape(epo_crit.x, [sz(1) sz(2)*sz(3)]);
% determine max/min for each epoch and channel:
mmax= max(epo_crit.x, [], 1);
mmin= min(epo_crit.x, [], 1);
% determine the maximum difference (max-min) across channels
if opt.AllChannels,
  dmaxmin= min(reshape(mmax-mmin, sz(2:3)), [], 1);
else
  dmaxmin= max(reshape(mmax-mmin, sz(2:3)), [], 1);
end
iArte= find(dmaxmin > threshold);

if opt.Verbose,
  fprintf('%d artifact trials removed (max-min>%d uV)\n', ...
          length(iArte), threshold);
end
epo= proc_selectEpochs(epo, 'not',iArte);
