%This directory contains files helping functions and utilities used for the
%visualization functions.
%
%CMAP_* - Colormaps for the visualization of scalp maps or score matrices
%DEFOPT_* - Default property lists for visualizing specific types of data
%
%AXIS_* - Helping functions for handling axes
%FIG_* - Helping functions for handling figures
%GRIDUTIL_* - Helping functions for grid_plot
%MNTUTIL_* - Helping functions for handling montages
%PLOTUTIL_* - Helping functions for plot_channel
%VISUTIL_* - Various helping functions


%%% TO-DO / CHANGES %%%
%
% fig_publish, fig_closeIfExists: extremely simple, only used in
% online/calibration/bbci_calibrate_ERPSpeller.m and
% online/calibration/bbci_calibrate_csp.m,
% remove?
%
% axis_getEffectivePosition: only used in plotutil_colorbarAside, made
% private!
%
% axis_getColorbarHandle: only used in visutil_addColormap and
% visutil_acmAdaptCLim, made private!
%
% removed unused axis_shiftRight, axis_shiftDown, axis_shiftLeft,
% axis_shiftCenter, axis_xTickLabel, mntutil_shrinkChannels
%
% fig_setBackgroundAxis: only used once by plot_scalpEvolutionPlusChannel,
% replace?
%
% fig_set: ???
%
% removed almost redundant fig_toolsoff
%
% gridutil_addScale, gridutil_getAxisPos, jvm_*, mntutil_posExt55:
% moved to visualization/private
%
%