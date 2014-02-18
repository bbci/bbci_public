function H= plot_channel(epo, clab, varargin)
%PLOT_CHANNEL - Plot the classwise averages of one channel of 1D (time OR
% frequency) or 2D data (time x frequency)
%
%Synopsis:
% H= plot_channel(EPO, CLAB, <OPT>)
%
%Input:
% EPO:  Struct of epoched signals, see makeEpochs
% CLAB: Name (or index) of the channel to be plotted.
% OPT:  Struct or property/value list of optional properties, see
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
  if ~isempty(varargin)
    opt1D= plotutil_channel1D;
    opt= opt_structToProplist(opt_substruct(opt_proplistToStruct(varargin{:}),opt1D(:,1)));
  else
    opt=varargin;
  end
  H= plotutil_channel1D(epo, clab, opt{:});
else
  if ~isempty(varargin)
    opt2D= plotutil_channel2D;
    opt=opt_structToProplist( opt_substruct(opt_proplistToStruct(varargin{:}),opt2D(:,1)));
  else
    opt=varargin;
  end
  H= plotutil_channel2D(epo, clab, opt{:});
end
