function H= plot_cspAnalysis(fv, mnt, W, A, la, varargin)
%PLOT_CSPANALYSIS - Show CSP filters and patterns as topographies
%
%Synopsis:
% H= plot_cspAnalysis(FV, MNT, CSP_W, CSP_A, CSP_EIG, <OPT>)
%
%Input:
% FV: data structure on which the CSP analysis was performed
% MNT: electrode montage, see getElectrodePositions
% CSP_W: CSP 'demixing' matrix (filters in columns)
% CSP_A: CSP 'mixing' matrix (patterns in rows)
% CSP_EIG: eigenvalues of CSP patterns
% OPT: struct or property/value list of optional properties:
%  .RowLayout    - if true, shows filter/pattern pairs in rows, rather than
%                  the default as columns
%  .MarkPatterns - vector of indices: these patterns are marked
%  .MarkStyle    - the outline of the marked scalps is marked by setting
%                  its properties to this property/value list (given in a
%                  cell array)
%  .ColorOrder   - can be used to give scalp outlines class specific colors
%  .NComps       - select top NComps patterns for both class (only for
%                  two-class cases)
%
%Output:
% H: struct of handles to graphic objects
%
%For the issue of interpreting spatial patterns (and not filters), see
%[Haufe et al, NeuroImage 2014].


props= {'ScalePos',      'none',                         'CHAR';
        'Title',         1,                              'BOOL';
        'MarkPatterns',  [],                             'DOUBLE|CHAR';
        'MarkStyle',     {'LineWidth',3},                'PROPLIST';
        'RowLayout',     0,                              'BOOL';
        'ColorOrder',    [],                             'DOUBLE[- 3]';
        'CspClab',       [],                             'CELL{CHAR}';
        'NComps',        [],                             'DOUBLE'};

if nargin==0,
  H= props; return
end

opt= opt_proplistToStruct(varargin{:});
[opt, isdefault]= opt_setDefaults(opt, props);
opt_checkProplist(opt, props);

sc_opt = defopt_scalp_csp('ScalePos',opt.ScalePos);

if opt.RowLayout
    AxesLayout = {[0 .01 0],[.05 .01 0]};
else
    AxesLayout = {[0 .01 .05],[0 .01 0]};
end

if isequal(opt.Title,1),
  if isfield(fv, 'title'),
    opt.Title= fv.Title;
  else
    opt.Title= '';
  end
end

if ~exist('la','var'),
  la= [];
end

nClasses= size(fv.y,1);

if ~isempty(opt.NComps) && nClasses == 2
  d=size(W,2);
  W=W(:,[1:opt.NComps,d:-1:d-opt.NComps+1]);
  A=A([1:opt.NComps,d:-1:d-opt.NComps+1],:);
  la=la([1:opt.NComps,d:-1:d-opt.NComps+1]);
end

nPat= size(W,2);
nComps= ceil(nPat/nClasses);

if ischar(opt.MarkPatterns),
  if ~strcmpi(opt.MarkPatterns, 'all'),
    warning('unknown value for opt.MarkPatterns ignored');
  end
  opt.MarkPatterns= 1:nPat;
end

if isempty(opt.CspClab),
  opt.CspClab= cellstr([repmat('csp', [nPat 1]) int2str((1:nPat)')])';
end
if ~isfield(fv, 'origClab'),
  mnt= mnt_adaptMontage(mnt, fv.clab);
else
  mnt= mnt_adaptMontage(mnt, fv.origClab);
end

clf;
k= 0;
for rr= 1:nClasses,
  for cc= 1:nComps,
    k= k+1;
    if k>nPat,
      continue;
    end
    if opt.RowLayout,
      ri= (rr-1)*nComps + cc;
      H.ax_filt(cc,rr)= ...
          subplotxl(2, nPat, [1 ri], AxesLayout{:});
      H.ax_pat(cc,rr)= ...
          subplotxl(2, nPat, [2 ri], AxesLayout{:});
    else
      H.ax_filt(cc,rr)= ...
          subplotxl(nComps, 2*nClasses, [cc rr*2-1], AxesLayout{:});
      H.ax_pat(cc,rr)= ...
          subplotxl(nComps, 2*nClasses, [cc rr*2], AxesLayout{:});
    end
    if ~isempty(A),
      H.scalp(cc,rr)= plot_scalp(mnt, A(:,k), sc_opt);
    else
      H.scalp(cc,rr).head= [];
      H.scalp(cc,rr).nose= [];
    end
    axes(H.ax_filt(cc,rr));
    H.scalp_filt(cc,rr)= plot_scalp(mnt, W(:,k), sc_opt);
    hh= [H.scalp(cc,rr).head, H.scalp(cc,rr).nose, ...
         H.scalp_filt(cc,rr).head, H.scalp_filt(cc,rr).nose];
    if ~isempty(opt.ColorOrder),
      set(hh, 'Color',opt.ColorOrder(rr,:));
    end
    if ismember(k, opt.MarkPatterns,'legacy'),
      set(hh, opt.MarkStyle{:});
    end
    if isempty(la),
      label_str= opt.CspClab{k};
    else
      label_str= sprintf('{\\bf %s}  [%.2f]', opt.CspClab{k}, la(k));
    end
    if opt.RowLayout,
      H.label(cc,rr)= title(label_str);
      set(H.label(cc,rr), 'FontSize',12);
      if cc==1&&rr==1
          axes(H.ax_pat(cc,rr));
          yh(1) = ylabel('Pattern');
          axes(H.ax_filt(cc,rr));
          yh(2) = ylabel('Filter');
          set(yh,'Visible','on')
      end
    else
      axes(H.ax_pat(cc,rr));
      H.label(cc,rr)= ylabel(label_str);
      if cc==1
          axes(H.ax_pat(cc,rr));
          title('Pattern');
          axes(H.ax_filt(cc,rr));
          title('Filter');
      end
    end
  end
end
set(H.label, 'Visible','on');

%if ~isempty(opt.Title) && ~isequal(opt.Title,0),
%  H.Title= addTitle(untex(opt.Title), 1, 1);
%end
