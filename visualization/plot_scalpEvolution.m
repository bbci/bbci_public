function H= plot_scalpEvolution(erp, mnt, ival, varargin)
%H= plot_scalpEvolution(erp, mnt, ival, <opts>)
%
% Draws scalp topographies for specified intervals,
% separately for each each Class. For each Classes topographies are
% plotted in one row and shared the same Color map scaling. (In future
% versions there might be different options for Color scaling.)
%
% IN: erp  - struct of epoched EEG data. For convenience used Classwise
%            averaged data, e.g., the result of proc_average.
%     mnt  - struct defining an electrode montage
%     ival - [nIvals x 2]-sized array of interval, which are marked in the
%            ERP plot and for which scalp topographies are drawn.
%            When all interval are consequtive, ival can also be a
%            vector of interval borders.
%     opts - struct or property/value list of optional fields/properties:
%      .IvalColor - [nColors x 3]-sized array of rgb-coded Colors
%                    with are used to mark intervals and corresponding 
%                    scalps. Colors are cycled, i.e., there need not be
%                    as many Colors as interval. Two are enough,
%                    default [0.6 1 1; 1 0.6 1].
%      .LegendPos - specifies the position of the legend in the ERP plot,
%                    default 0 (see help of legend for choices).
%      the opts struct is passed to plot_scalpPattern
%
% OUT H - struct of handles to the created graphic objects.
%
%See also plot_scalpEvolutionPlusChannel, plot_scalpPatterns, plot_scalp.

% 01-2005 Benjamin Blankertz


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
