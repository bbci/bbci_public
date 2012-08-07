function H= plot_channel(epo, clab, varargin)
%PLOTCHANNEL - wrapper function calling specialized functions to plot the 
%Classwise averages of one channel. Function plot_channel2D Plots 
% 2D data (time x amplitude OR FreqLimuency x amplitude); 
% plot_channel3D plots 3D data (FreqLimuency x time x amplitude). 
%
%Usage:
% H= plot_channel(EPO, CLAB, <OPT>)
%
%Input:
% EPO  - Struct of epoched signals, see makeEpochs
% CLAB - Name (or index) of the channel to be plotted.
%
% OPT  is a struct or property/value list of optional properties, see
% plot_channel2D for 2D plots and plot_channel3D for 3D plots.
%
%Output:
% H - Handle to several graphical objects.
%
% See plot_channel2D and plot_channel3D for more infos on plotting.

if nargin==0
    fprintf('\nPlease type\n\n   plot_channel2D\n\nfor 2D data plotting or\n\n   plot_channel3D\n\nfor 3D data plotting.\n\n')
    return
end

if getDataDimension(epo)==2
  H = plot_channel2D(epo,clab,varargin{:});
else
  H = plot_channel3D(epo,clab,varargin{:});
end
