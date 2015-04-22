# A Guide for Implementing new Calibration functions

The function `bbci_calibrate` is just a wrapper that provides some basic
functionality, like loading the calibration data. The calibration of the BBCI
Online system is performed by calibration specific subfunctions, which should be
named `bbci_calibrate_XYZ` with 'XYZ' being a specific and compact description
of the type of calibration. The calling convention for the `bbci_calibrate_*`
functions is described in `online/calibration/Contents.m`. Calibration functions
that are of 'general interest' should be stored in this folder. (Please, add a
short description in the `Contents.m` file.) More specilized calibration
functions should be filed under `bbci/acquisition/setups/*`.

```matlab
[BBCI, DATA]= bbci_calibate_XYZ(BBCI, DATA)
```

The objective of calibration functions is to define the online processing in the
variable `bbci`, based on the calibration data given in the fields `cnt`, `mrk`,
and `mnt` of `data`. Calibration specific parameters that can be selected by the
user are provided in `bbci.calibrate.settings`. This is the only (sub-) field of
the variable `bbci` that should be read by the calibration function. Otherwise,
the `bbci` variable is only used to store information of specific online
processing.

The field `data.isnew` indicates whether calibration data is new (loaded for the
first time or reloaded) or whether it is the same as before. In the latter case,
some steps of calibration might be omitted. For example, it might not be
required to run artifact rejection again in subsequent runs (unless parameters
that would affect artifact rejection are modified in `bbci.calibrate.settings`.
In order to able to check which settings have been changed since the last run,
`data.previous_settings` holds the settings of the previous calibration run.
(This functionality is provided by `bbci_calibrate`.)

The result of the selection of parameters should be stored in `data.result`.
This should be warranted, at least of the parameters that can be unspecified in
`bbci.calibrate.settings` (typically by not defining them, or be defining them
as 'auto'). But other results of the calibration process (e.g., list of rejected
trials) should also be stored in `data.result` for documentation.

Finally, `data.figure_handles` should hold the handles of all Matlab figures
that should be stored by `bbci_save`. If this field is not defined, `bbci_save`
will save all Matlab figures (if saving figures is requested by
`bbci.calibrate.save.figures`).
