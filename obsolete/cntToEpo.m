function [epo, valid]= cntToEpo(varargin)

bbci_obsolete(mfilename, 'proc_segmentation');
[epo, valid]= proc_segmentation(varargin{:});
