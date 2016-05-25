function [dat, varargout] = proc_regressOutComponents(dat, s, varargin)
%PROC_REGRESSOUTCOMPONENTS - Artifact removal by regressing out components 
%
% [DAT, W, A, S_HAT] = regress_out_component(DAT, S)
%
%
%Arguments:
% DAT - data structure of epoched data
% s   - time course of components to be removed, size(s) = [T, n_components]
%       n_components can be more than one
% OPT - struct or property/value list of optional properties:
%  .return  - determines what additional matrices are returned. Valid values are
%             'all' (filters, patterns, and estimated components are returned,
%             in that order'),
%             'none' (default, no other matrices are returned) 
%
%Returns
% DAT               - Updated data structure. Note that this method reduces the rank of DAT.x
% W (optional)      - filter matrix of size(W) = [n_components, n_channels], which is used to
%                     estimate the components from the data.
% A (optional)      - pattern matrix of size(A) = [n_channels, n_components], which
%                     shows how each of the components in s project to the channels
%                     in X.
% s_hat (optional)  - the estimate of s, which is extracted from DAT.x using W
%
%
%Description:
% Uses regression to remove the time course(s) contained in s from the data
% contained in DAT. s could be the eye movements measured with EOG channels
% and DAT could contain the remaining EEG channels. In this case the EOG signal
% that is contained in DAT.x will be removed (as best as possible, assuming a
% stationary eye movement pattern).
% 
%References:
% Parra, L. C., Spence, C. D., Gerson, A. D., & Sajda, P. (2005), 
% "Recipes for the linear analysis of EEG. Neuroimage, 28(2), 326-341

% Author(s): Sven Daehne, Mihail Bogojeski

props= { 'return'    'none'      'CHAR'};

if nargin==0,
  dat = props; return
end

opt= opt_proplistToStruct(varargin{:});
[opt, isdefault]= opt_setDefaults(opt, props);
opt_checkProplist(opt, props);

varargout={};
dat = misc_history(dat);
misc_checkType(dat, 'STRUCT(x clab)');
misc_checkType(s, 'DOUBLE[- -]'); 
X = dat.x;
misc_checkType(X, 'DOUBLE[- -]');

T = size(X,1);
if not(size(s,1) == T)
    error('X and s must have the same number of samples! size(X,1) = %d, size(s,1) = %d', size(X,1),size(s,1));
end

% regression filter and patterns for the components
Cx = X'*X;
Cs = s'*s;
W = Cx \ X' * s; % regression weights for s
A = Cx*W/Cs; % spatial patterns of s

% remove estimate of s from the data
s_hat = X * W;
X_new = X - s_hat*A';

dat.x = X_new;
if strcmp(opt.return, 'all')
  varargout{1} = W;
  varargout{2} = A;
  varargout{3} = s_hat;
end
