
# Contents of the _online_ folder

**This directory contains the files that are required to calibrate a BBCI
processing model, to save it, and to apply it to continuously incoming data.**

The parent folder contains the basic functions for online processing. It has
several subfolders. Most of the functions therein are for internal use and
should not be called directly. However, for an advanced use of the online
processing, knowledge about functions in some subfolders is required for setting
up the system, see below.

Detailed information about the functions can be found in the help files of the
Matlab functions and in the function reference **[Basti, add link]**.

* [online](#Online) - _Parent folder with basic functions_
* [acquisition](#Acquisition) - _Functions for acquiring signals_
* [adaptation](#Adaptation) - _Functions for adapting classifiers_
* [calibration](#Calibation) - _Functions for calibrate the system_
* [control](#Control) - _Control function translate classifier output to a control signals_
* [demos](#Demos) - _Demo code for online and simulated online processing_
* [feedback](#Feedback) - _Feedbacks written in Matlab_

* [apply\_functions](#ApplyFunctions) - _Internal_
* [calibration\_functions](#CalibrationFunctions) - _Internal_
* [logging](#Logging) - _Internal_
* [utils](#Utils) - _Internal_


## Functions in the _online_ folder   <a id="Online"></a>

* `BBCI_CALIBRATE` - Establish a classifier based on calibration data
* `BBCI_SAVE` - Save BBCI classifier (and all information required for online
  operation in a file.
* `BBCI_APPLY` - Apply BBCI classifier to continuously acquired data
* `BBCI_APPLY_UNI` - Same as `bbci_apply` but for simpler use cases (unimodal
  data and features and single classifier)
* `BBCI_LOAD` - Load BBCI classifier
* `BBCI_APPLY_STRUCTRES` - Help file describing the data structures
* `BBCI_CALIBRATE_STRUCTURES` - Help file describing the data structures


## Subfolder _acquisition_   <a id="Acquisition"></a>

This folder contains the so-called ACQUIRE functions for bbci_apply. These
functions acquire small bolcks of signals (and maybe event markers from a
specific measurement device, and provide it for online processing. If no new
data is available, they return an empty structure.

These functions have the following format:

```
BBCI_ACQUIRE_XYZ - Online data acquisition from device XYZ

Synopsis:
  STATE= bbci_acquire_XYZ('init', <PARAM>)
  [CNTX, MRKTIME, MRKDESC, STATE]= bbci_acquire_XYZ(STATE)
  bbci_acquire_XYZ('close')
  bbci_acquire_XYZ('close', STATE)

Arguments:
  PARAM - Optional arguments, specific to XYZ.

Output:
  STATE - Structure characterizing the incoming signals; fields:
     'fs', 'clab', and intern stuff
  CNTX - 'acquired' signals [Time x Channels]
  The following variables hold the markers that have been 'acquired' within
  the current block (if any).
  MRKTIME - DOUBLE: [1 nMarkers] position [msec] within data block.
      A marker occurrence within the first sample would give
      MRKTIME= 1/STATE.fs.
  MRKDESC - CELL {1 nMarkers} descriptors like 'S 52'
```

## List of ACQUIRE functions (prefix `bbci_acquire_` is left out)

* `bv`:      Acquire data from BV Recorder (option 'Remote Data Access' must be enabled in the BV Recorder settings!)
* `nirx`:    Acquire data from a NIRx system
* `offline`: Simulate online acquisition by returning small chunks of signals from an initially given data file.
* `randomSignals`: Generate random signals


## Subfolder _adaptation_   <a id="Adaptation"></a>

No description available yet.


## Subfolder _calibration_   <a id="Calibration"></a>

This folder contains the so-called CALIBRATE functions, to be called by
`bbci_calibrate`. These functions receive as input the calibration data and the
BBCI structure, which holds specific parameters for the calibration procedure in
the field `BBCI.calibrate`. The output is and updated BBCI structure which has
all the necessary information for online operation, i.e., for `bbci_apply`, see
`bbci_apply_strctures`.

The CALIBRATE functions have the following format:

```
BBCI_CALIBRATE_XYZ - Calibrate online system for paradigm XYZ

Synopsis:
 [BBCI, DATA]= bbci_calibate_XYZ(BBCI, DATA)
 
Arguments:
  BBCI - The field BBCI.data holds the calibration data and the field
     'calibrate' holds parameters specific to calibration XYZ.
  DATA - Hold the calibration data in fields 'cnt', 'mrk', and 'mnt'.
     Furthermore, DATA.isnew indicates whether calibration data is
     new (loaded for the first time or reloaded) or whether it is the
     same as before. In the latter case, some steps of calibration
     might be omitted (subject to changes in BBCI.calibrate.settings).
     In order to check, what settings have been changed since the last
     run, DATA.previous_settings hold the settings of the previous
     calibration run.
  
Output:
  BBCI - Updated BBCI structure in which all necessary fields for
     online operation are set, see bbci_apply_structures.
  DATA - Updated DATA structure, with the result of selections being
     stored in DATA.result.
     Furthermore, DATA.figure_handles should hold the handles of all
     figures that should be stored by bbci_save. If this field is not
     defined, bbci_save will save all Matlab figure (if saving figures
     is requested by BBCI.calibrate.save.figures==1).
```

To get a description on the structures `BBCI` and `DATA`, type `help bbci_calibrate_structures`.

## Conventions (for programmers for new calibration functions):

The CALIBRATE functions should *only* read the (sub)field
`bbci.calibrate.settings`. However, this field should *not* be modified. (It is
debateble, whether default values for unspecified parameters should be filled
in.) Selection of values for parameters which are unspecified by the user (or
specified as 'auto') should *not* be stored in `bbci.calibrate.settings`, but in
data.result under the save field name.

## List of CALIBRATE functions (prefix `bbci_calibrate_` is left out)

- `ERP_Speller`: Setup for the online system to perform classification for an
  ERP Speller in the stardard format.
- `csp`: Setup for classifying SMR Modulations with CSP filters and log
  band-power features
- `csp_plus_lap`: Additionally to optimized CSP filters some Laplacian channels
  are selected and used for classification. These are meant to be reselected
  during supervised adaptation with `bbci_adaptation_csp_plus_lap`.


## Subfolder _control_   <a id="Control"></a>

This folder contains the so-called CONTROL functions for bbci_apply. These
functions transform the classifier output into the control signal (PACKET), that
will be sent to the application via UDP. The PACKET is formatted as a
variable/value list in a CELL.

These functions have the following format:

```
  BBCI_CONTROL_XYZ - Generate control signal for application XYZ
  
  Synopsis:
    [PACKET, STATE]= bbci_control_XYZ(CFY_OUT, STATE, EVENT_INFO, <PARAMS>)
  
  Arguments:
    CFY_OUT - Output of the classifier
    STATE - Internal state variable, which is empty in the first call of a
        run of bbci_apply.
    EVENT_INFO - Structure that specifies the event (fields 'time' and 'desc')
        that triggered the evaluation of this control. Furthermore, EVENT_INFO
        contains the whole marker queue in the field 'all_markers'.
    PARAMS - Additional parameters that can be specified in bbci.control.param
        are passed as further arguments.
  
  Output:
   PACKET: Variable/value list in a CELL defining the control signal that
       is to be sent via UDP to the application.
   STATE: Updated internal state variable
```

## List of CONTROL functions (prefix `bbci_control_` is left out):

* `ERP_Speller`: ERP-based Hex-o-Spell, one output for each complete sequence
* `ERP_Speller_binary`: ERP-based Hex-o-Spell, one output for each stimulus


## Subfolder _demos_   <a id="Demos"></a>

No description available yet.


## Subfolder _feedback_    <a id="Feedback"></a>

No description available yet.


## Subfolder _apply\_functions_   <a id="ApplyFunctions"></a>

**Internal:** This directory contains functions that are used in `bbci_apply`.

* `BBCI_APPLY_SETDEFAULTS` - Set default values in bbci structure for bbci_apply
* `BBCI_APPLY_INITDATA` - Initialize the data structure of bbci_apply
* `BBCI_APPLY_ACQUIREDATA` - Fetch data from acquisition hardware
* `BBCI_APPLY_EVALSIGNAL` - Process cont. acquired signals and store in buffer
* `BBCI_APPLY_EVALCONDITION` - Evaluate conditions which trigger control signals
* `BBCI_APPLY_QUERYMARKER` - Check for acquired markers
* `BBCI_APPLY_EVALFEATURE` - Perform feature extration
* `BBCI_APPLY_GETSEGMENT` - Retrieve segment of signals from buffer
* `BBCI_APPLY_EVALCLASSIFIER` - Apply classifier to feature vector
* `BBCI_APPLY_EVALCONTROL` - Evaluate control function to classifier output
* `BBCI_APPLY_SENDCONTROL` - Send control signal to application
* `BBCI_APPLY_RESETDATA` - Reset the data structure of bbci_apply
* `BBCI_APPLY_EVALQUITCONDITION` - Evalutate whether bbci_apply should stop


## Subfolder _calibration_functions_   <a id="CalibrationFunctions"></a>

**Internal:** This directory contains functions that are used in
`bbci_calibrate`.

* `BBCI_CALIBRATE_SETDEFAULTS` - Set default values in bbci structure for
  bbci_calibrate
* `BBCI_CALIBRATE_SET` - Specify calibration-specific parameters, or copy them
  from the previous run of bbci_calibrate.

The following function is also useful outside of bbci_calibrate:

* `BBCI_CALIBRATE_EVALFEATURE`

## Subfolder _logging_   <a id="Logging"></a>

For internal use only - no description available.


## Subfolder _utils_   <a id="Utils"></a>

No description available yet.
