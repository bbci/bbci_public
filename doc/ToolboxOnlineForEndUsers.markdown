## Online Use of the BBCI Toolbox from a User's Perspective

For the 'user' of the BBCI online system, essentially two operations are
required: *calibration* of the system and online *application* of the system.
These operations are performed by the functions `bbci_calibration` and
`bbci_apply` respectively. After calibration, the calibrated system can be saved
via `bbci_save` (advisable, but not required). Here is a simple (but complete)
example, how the system can be calibrated and started in online operation:

```matlab
% Define in 'bbci' the type of calibration and calibration specific parameters:
bbci= struct('calibrate');
bbci.calibrate.fcn= @bbci_calibrate_csp;
bbci.calibrate.settings.classes= {'left', 'right'};

% Run calibration:
[bbci, data]= bbci_calibrate(bbci);

% Optionally specify in 'bbci' application specific parameters:
bbci.feedback.receiver= 'matlab';
bbci.feedback.fcn= @bbci_feedback_cursor;
bbci.feedback.opt= struct('trials_per_run', 80);

% Saving the classifier is not necessary for operation, but advisable.
% Optinally feature vectors and figures of the calibration can be saved.
bbci_save(bbci, data);

% Start online operation of the BBCI system:
[bbci, data]= bbci_apply(bbci);
```

This simple scripts makes some assumptions on the data, e.g., that the markers
for the two conditions _left_ and _right_ are `1` and `2`.


The user can control the calibration via the fields of `bbci.calibrate`:

I. Defining the calibration file:

| Field            | Description                                                         |
|------------------|---------------------------------------------------------------------|
| `.folder`        | CHAR, default `BTB.Tp.Dir` (refering to the global variable `BBCI`) |
| `.file`          | CHAR, no default: must be specified                                 |
| `.read_fcn`      | FUNC HANDLE, default @file_readBV                                   |
| `.read_param`    | CELL, default {}                                                    |
| `.marker_fcn`    | FUNC HANDLE, default []                                             |
| `.marker_param`  | CELL, default {}                                                    |
| `.montage_fcn`   | FUNC HANDLE, default @mnt_setElectrodePositions                     |
| `.montage_param` | CELL, default {}                                                    |


II. Defining the type of calibration and calibration specific parameters

| Field       | Description                                                                                                                                                                                                |
|-------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `.fcn`      | FUNC HANDLE, no default: must be specified; this function should have the prefix `bbci_calbrate_` and is called by the wrapper function` bbci_calibrate`                                                   |
| `.settings` | STRUCT defining the calibration specific parameters. Which parameters can be specified and their meaning should be described in the help of the specific calibration function. There is no general format. |


III. Defining whether and how information should be logged


`.log`

| Field                | Description                        |
|----------------------|------------------------------------|
| `.output`            | CHAR, default 'screen&file'        |
| `.folder`            | CHAR, default TODAY_DIR            |
| `.file`              | CHAR, default 'bbci_calibrate_log' |
| `.force_overwriting` | BOOL, default 0                    |


IV. Defining what and how calibration data should be saved

`.save`

| Field           | Description                                                                                                                                   |
|-----------------|-----------------------------------------------------------------------------------------------------------------------------------------------|
| `.file`         | CHAR, default 'bbci_classifier'                                                                                                               |
| `.folder`       | CHAR, default TODAY_DIR                                                                                                                       |
| `.overwrite`    | BOOL, default 1. If 0, numbers are appended                                                                                                   |
| `.raw_data`     | BOOL, default 0. If 1, also calibration source data (fields cnt, mrk, and mnt) are stored. Otherwise only the other fields of data are stored |
| `.data`         | CHAR, default separately                                                                                                                      |
| `.figures`      | BOOL, default 0. If true, Matlab figures generated by calibration are saved in a subfolder figures                                            |
| `.figures_spec` | CELL, default {'paperSize','auto'}: specification for saving the figures: this is passed to the function printFigure                          |  

---

## Interactively Optimize Calibration Parameters

For rigorous experimental studies it is advisable to have the calibration
completely deterministic, i.e., without having the experimenter tweaking
parameters to the calibration data. (However, this view point is debateble.)
Anyway, for exploratory studies, interactive optimization of the calibration
process to the data of each participant is desirable. In the BBCI Online System
this can be done by iterating the specification of calibration parameters in
`bbci.calibrate.settings` and rerunning `bbci_calibrate`. In order to speed up
and facilitate this process, some tricks are good to know (which also have to be
taken into account when writing new *calibrate functions*.

To avoid re-loading the calibration data each time, you can provide the `data`
structure, which is obtained as second output argument of `bbci_calibrate`, as
further input argument to `bbci_calibrate`:

```matlab
% Run calibration for the first time
[bbci, data]= bbci_calibrate(bbci);

% Change some calibration specific settings, e.g.,
bbci.calibrate.settings.band= [10 13];

% Run calibration again. Calibration data is stored in the variable data,
% so it needs not to be reloaded.
[bbci, data]= bbci_calibrate(bbci, data);
```

More over, the calibration-specific function `bbci_calibrate_*` might be
implemented such that some processing steps re be reused (without the user
having to take care about that). For example, it might not be required to run
artifact rejection again in subsequent runs (unless parameters that would affect
artifact rejection are modified).

Another mechanism (which also has to be taken into account by programmers of new
calibrate functions) lets users take over selections that might have been
performed by a calibration run: All results of parameter selections during
calibration should be store in `data.result`. In particular, the selected values
for parameters that have been declared as 'auto' in `bbci.calibrate.settings`
are stored in `data.result` in the same field. For example,

```matlab
% This example assumes bbci.calibrate.fcn= @bbci_calibrate_csp
% The following is default anyway, but made explicit here for demonstration
>> bbci.calibrate.settings.band= 'auto';
>> [bbci, data]= bbci_calibrate(bbci);
% The result of the selection of the frequency band is stored here
>> data.result.band
ans =
    9	 13
% Still, the settings in bbci are unchanged (in contrast to the old system)
>> bbci.calibrate.settings.band
ans =
auto
% For inspecting and changing bbci.calibrate.setting, the function
% bbci_calibrate_set can be used, or the short hand bc_set.
% Checking values (same as above)
>> bc_set(bbci, 'band')
The value of 'band' is:
'auto'
% Setting values explicitly:
>> bc_set(bbci, 'band', [10 13])
>> bc_set(bbci, 'band')
The value of 'band' is:
[10,13]
% Providing data as further input, selections of the calibration can be copied:
>> bbci= bc_set(bbci, data, 'band');
>> bc_set(bbci, 'band')
The value of 'band' is:
[9,13]
% The function allows copying several parameters at the same time
>> bbci= bc_set(bbci, data, 'band', 'ival', 'classes');
% You can revert to the original value of a parameter by bbci_calibrate_reset
>> bbci= bbci_calibrate_reset(bbci, 'band');
>> bc_set(bbci, 'band')
The value of 'band' is:
'auto'
```
