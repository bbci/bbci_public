function H= plot_channel(epo, clab, varargin)
%PLOTCHANNEL - wrapper function calling specialized functions to plot the 
%Classwise averages of one channel. Function plotutil_channel1D plots 
% 1D data (time OR frequency); plotutil_channel2D plots 2D data (time x frequency). 
%
%Usage:
% H= plot_channel(EPO, CLAB, <OPT>)
%
%Input:
% EPO  - Struct of epoched signals, see makeEpochs
% CLAB - Name (or index) of the channel to be plotted.
%
% OPT  is a struct or property/value list of optional properties, see
% plotutil_channel1D for 1D plots and plotutil_channel2D for 2D plots.
%
%Output:
% H - Handle to several graphical objects.
%
% See also plotutil_channel1D, plotutil_channel2D 


if nargin==0,
  H= opt_catProps(plotutil_channel1D, plotutil_channel2D);
  return
end

if nargin<2,
  clab= 1;
end

if util_getDataDimension(epo)==1
  H= plotutil_channel1D(epo, clab, varargin{:});
else
  H= plotutil_channel2D(epo, clab, varargin{:});
end
