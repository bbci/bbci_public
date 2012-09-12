function dat= proc_logarithm(dat)
%PROC_LORARITHM - computes the natural logarithm
%
%Synopsis:
% dat= proc_logarithm(dat);
%
%Arguments:
%     dat     -  continuous or epoched EEG data
% 
%Returns:
%     dat     -  updated data struct
%     
dat = misc_history(dat);

dat.x= log(dat.x);
