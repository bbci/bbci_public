function h= plot_scalpPatterns(erp, mnt, ival, varargin)
%SCALPPATTERNS - Display Classwise topographies
%
%Usage:
% H= plot_scalpPatterns(ERP, MNT, IVAL, <OPTS>)
%
%Input:
% ERP  - struct of epoched EEG data. For convenience used Classwise
%        averaged data, e.g., the result of proc_average.
% MNT  - struct defining an electrode montage
% IVAL - The time interval for which scalp topographies are to be plotted.
%        May be either one interval for all Classes, or specific
%        intervals for each Class. In the latter case the k-th row of IVAL
%        defines the interval for the k-th Class.
% OPTS - struct or property/value list of optional fields/properties:
%  The opts struct is passed to plot_scalpPattern.
%
%Output:
% H: Handle to several graphical objects.
%
%See also plot_scalpEvolution, plot_scalpPatternsPlusChannel, plot_scalp.

% Author(s): Benjamin Blankertz, Jan 2005
if nargin==0
    h=plot_scalpPatternsPlusChannel; return
end

h= plot_scalpPatternsPlusChannel(erp, mnt, [], ival, varargin{:});

if nargout<1,
  clear h
end
