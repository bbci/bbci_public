function out= proc_zScore(epo, varargin)
%PROC_ZSCORE - calculates the (pseudo) z-score or normal score
%               as a dimensionless quantity (for two classes only)
%
%Synopsis:
% EPO= proc_zScore(EPO, <OPT>)
% EPO= proc_zScore(EPO, CLASSES)
%
%Arguments:
% EPO -      data structure of epoched data
%            epo.x should be at least 3-dimensional
%            (can handle more than 3-dimensional data, the average is
%            calculated across the last dimension)
% OPT struct or property/value list of optional arguments:
%  .Policy - 'mean' (default), 'nanmean', or 'median'
%  .Classes - classes of which the average is to be calculated,
%            names of classes (strings in a cell array), or 'ALL' (default)
%
%Returns:
% EPO     - updated data structure with new field(s)
%  .N     - vector of epochs per class across which average was calculated
%  .std   - standard deviation,
%           format as epo.x.

% Author(s): Benjamin Blankertz, long time ago
%            Andreas Ziehe, November 2007
%            JohannesHoehne, updated version 2013

props= {'Policy'  'mean'     '!CHAR(mean nanmean median)'
    'Classes' 'ALL'      '!CHAR'
    'Std'     1          'BOOL'};

if nargin==0,
    out = props; return
end

misc_checkType(epo, 'STRUCT(x clab)');

opt= opt_proplistToStruct(varargin{:});
[opt, isdefault]= opt_setDefaults(opt, props);
opt_checkProplist(opt, props);
epo = misc_history(epo);

%%
if ~isfield(epo, 'y'),
    warning('no classes label found: calculating average across all epochs');
    nEpochs= size(epo.x, ndims(epo.x));
    epo.y= ones(1, nEpochs);
    epo.className= {'all'};
end

if isequal(opt.Classes, 'ALL'),
    classes= epo.className;
end
if ischar(classes), classes= {classes}; end
if ~iscell(classes),
    error('classes must be given cell array (or string)');
end
nClasses= length(classes);

if max(sum(epo.y,2))==1,
    warning('only one epoch per class - nothing to average');
    out= proc_selectClasses(epo, classes);
    out.N= ones(1, nClasses);
    return;
end

out= rmfield(epo, intersect(fieldnames(epo),{'x','y','className'},'legacy'));
%  clInd= find(ismember(epo.className, classes));
%% the command above would not keep the order of the classes in cell 'ev'
evInd= cell(1,nClasses);
for ic= 1:nClasses,
    clInd= find(ismember(epo.className, classes{ic},'legacy'));
    evInd{ic}= find(epo.y(clInd,:));
end

sz= size(epo.x);
out.x= zeros(prod(sz(1:end-1)), nClasses);
this_std= zeros(prod(sz(1:end-1)), nClasses);
out.y= eye(nClasses);
out.className= classes;
out.N= zeros(1, nClasses);
epo.x= reshape(epo.x, [prod(sz(1:end-1)) sz(end)]);
for ic= 1:nClasses,
    switch(lower(opt.Policy)),  %% alt: feval(opt.Policy, ...)
        case 'mean',
            out.x(:,ic)= mean(epo.x(:,evInd{ic}), 2);
        case 'nanmean',
            out.x(:,ic)= nanmean(epo.x(:,evInd{ic}), 2);
        case 'median',
            out.x(:,ic)= median(epo.x(:,evInd{ic}), 2);
        otherwise,
            error('unknown policy');
    end
    
    if strcmpi(opt.Policy,'nanmean'),
        this_std(:,ic)= nanstd(epo.x(:,evInd{ic}), 0, 2);
    else
        this_std(:,ic)= std(epo.x(:,evInd{ic}), 0, 2);
    end
    
    out.N(ic)= length(evInd{ic});
end
out.x= reshape(out.x, [sz(1:end-1) nClasses]);

%compute standard deviation
this_std= reshape(this_std, [sz(1:end-1) nClasses]);
%compute z-scores
if length(sz) == 3
    out.x=(out.x(:,:,1)-out.x(:,:,2))./sqrt(this_std(:,:,1).^2/out.N(1)+this_std(:,:,2).^2/out.N(2));
elseif length(sz) == 2
    out.x=(out.x(:,1)-out.x(:,2))./sqrt(this_std(:,1).^2/out.N(1)+this_std(:,2).^2/out.N(2));
end


if opt.Std
    out.event.std = this_std;
end

out.y=1; %just one class left
out.yUnit='z-score';
%out.className=['z-score (' out.className{1} ', '  out.className{2} ...
%	       ')' ];

out.className= {sprintf('z( %s , %s )', out.className{1:2})};