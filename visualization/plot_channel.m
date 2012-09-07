function H= plot_channel(epo, clab, varargin)
%PLOTCHANNEL - wrapper function calling specialized functions to plot the 
%Classwise averages of one channel. Function plot_channel1D plots 
% 1D data (time OR frequency); plot_channel2D plots 2D data (time x frequency). 
%
%Usage:
% H= plot_channel(EPO, CLAB, <OPT>)
%
%Input:
% EPO  - Struct of epoched signals, see makeEpochs
% CLAB - Name (or index) of the channel to be plotted.
%
% OPT  is a struct or property/value list of optional properties, see
% plot_channel1D for 1D plots and plot_channel2D for 2D plots.
%
%Output:
% H - Handle to several graphical objects.
%
% See also plot_channel1D, plot_channel2D 


if nargin==0,
  H= opt_catProps(plot_channel1D, plot_channel2D);
  return
end

if util_getDataDimension(epo)==1
  H= plot_channel1D(epo, clab, varargin{:});
else
  H= plot_channel2D(epo, clab, varargin{:});
end
