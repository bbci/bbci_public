In BBCI\_APPLY there are two central structures.

1.  The 'bbci' structure specifies WHAT should be done and HOW: data
    acquisition, processing, feature extraction, classification,
    determining the control signal, and calling the application. It is
    the input to bbci\_apply.
2.  The 'data' structure is used to store the acquired signals, and
    various steps of processed data, as well as some state information.
    It is the working variable of bbci\_apply.

Structure BBCI
--------------

defaults are set in bbci\_apply\_setDefaults

bbci.source
:   Defines the sources for acquiring signals. struct array with fields:
    .acquire\_fcn
    :   `[STRING, default 'acquire_bv']`

    .acquire\_param
    :   `[CELL ARRAY, default {}]`: parameters to acquire\_fcn

    .min\_blocklength
    :   `[DOUBLE, default 40]` minimum blocklength [msec] that should be
        acquired before dat is passed to further processing (in
        bbci\_apply\_setDefaults a variant .min\_blocklength\_sa is
        added for convenience.)

    .clab
    :   `[CELL ARRAY of STRING, default {'*'}]`

    .log
    :   see bbci.log. This field specifies, whether source-specific
        information should be logged (which is reporting when the length
        of an acquired block is larger than .min\_blocklength)

bbci.marker
:   Defines how the acquired markers are stored. struct with fields:
    .queue\_length
    :   Specifies how many markers are stored in the marker queue (see
        data.marker). The markers in the queue are available for queries
        and evaluating conditions, see bbci\_apply\_queryMarker.

bbci.signal
:   Defines how the continuous signals are preprocessed and stored into
    the ring buffer. struct array with fields:
    .source
    :   `[DOUBLE, default 1]` specifies from which data source (see
        above) this signal is extracted

    .proc
    :   `[CELL ARRAY, one cell per proc function, each CELL is either a FUNHANDLE, or a CELL ARRAY {FUNC, PARAM}, where FUNC is a FUNHANDLE and PARAM is a CELL ARRAY of parameters to the function; default {}]`

    .buffer\_size
    :   `[DOUBLE, default 10000]` in msec

    .clab
    :   `[CELL ARRAY of STRING, default {'*'}]` The subset of
        bbci.source.clab that is used by the signal.

bbci.feature
:   Defines extraction of features from continuous signals. struct array
    with fields:
    .signal
    :   `[vector of DOUBLE, default 1]` specifies from which signal (see
        above) this feature is extracted

    .ival
    :   `vector [start_msec end_msec]` specifies the size of the epoch
        (is that correct??)

    .proc
    :   `[CELL ARRAY, one cell per proc function, each CELL is either a FUNHANDLE, or a CELL ARRAY {FUNC, PARAM}, where FUNC is a FUNHANDLE and PARAM is a CELL ARRAY of parameters to the function; default {}]`

bbci.classifier
:   Specifies classification (model and parameters). struct array with
    fields:
    .feature
    :   `[vector of DOUBLE, default 1]` specifies to which feature this
        classifier is applied

    .apply\_fcn
    :   `FUNHANDLE`

    .C
    :   `[STRUCT]` the trained classifier (which is passed to the apply
        function)

bbci.control
:   Defines how to translate the classifier output (and given the event
    marker) into the control signal. struct array with fields:
    .classifier
    :   `[vector of DOUBLE, default 1]` specifies which classifier
        output (see above) is translated to a control signal

    .fcn
    :   `[FUNHANDLE, default '']`

    .param
    :   `(if ~isempty(bbci.control.fcn))`

    .condition
    :   defines the events which evokes the calculation of a control
        signal: [] means evaluate control signal for each data packet
        that was acquired
        .marker
        :   CELL of STRINGs (??or rather [vector of DOUBLE]??)
            specifying the markers that evoke the calculation of a
            control signal (if
        .interval
        :   `[DOUBLE in msec]` (does this option make sense?)

        .overrun
        :   `[DOUBLE in msec]` after .marker this amount of signals must

            -   have been required (such that epochs of all required
            -   feature can be obtained)

bbci.feedback
:   Defines where and how the control signal is sent. struct array with
    fields:
    .control
    :   `[vector of DOUBLE, default 1]` specifies which control signals
        (see above) are send to the feedback application

    .receiver
    :   `'matlab', 'pyff', 'screen', or 'tobi-c'`

bbci.adaptation
:   Specifies whether, what and how adaptation should be done. struct
    with fields
    .active
    :   `BOOL` whether adaptation is switched on

    .fcn
    :   `FUNHANDLE` adaptation function.

    .param
    :   `CELL` parameters that are passed to the adaptation.fcn

    .log
    :   see bbci.log. This field specifies, whether information about
        adaptation should be logged

bbci.quit\_condition
:   Defines the condition when bbcu\_apply should quit. struct with
    fields
    .running\_time
    :   `[DOUBLE in sec, default inf]`

    .marker
    :   `[CHAR or CELL ARRAY of CHAR, default '']`

bbci.log
:   Defines whether and how information should be logged
    .output
    :   `0 (or 'none')` for no logging, or `'screen'`, or `'file'`, or
        `'screen&file'`; `'screen'` is default if bbci.feeback.receiver
        is empty, otherwise 0.

    .filebase
    :   `CHAR` filename of logfile. May include `'$TODAY_DIR'` and
        `'$VP_CODE'`, which are then replaced by the values of the
        respective global variables.

    .time\_fmt
    :   `CHAR` print format of the time, default `'%08.3fms'`

    .clock
    :   `BOOL` specifies whether the clock should also be logged,
        default 0.

    .classifier
    :   `BOOL` specifies whether the classifer should also be logged,
        default 0.

Optionally further features:

-   remote\_control (let parameters be changed over UDP, e.g. by a GUI)?

Structure DATA
--------------

initialized in bbci\_apply\_initData.m

data.source
:   struct array with fields:
    .state
    :   state structure of acquire function
    .x
    :   recent block of acquired data
    .fs
    :   sampling rate
    .clab
    :   `CELL` of channel labs in source.x (these are selected by
        bbci.source.clab)

    .sample\_no
    :   number of the last sample in the recent data (source.x) relative
        to the start of bbci\_apply
    .time
    :   time of acquisition, i.e. 'sample\_no' converted to msec

data.marker
:   struct with fields:
    .time
    :   `[DOUBLE: 1xMARKER.QUEUELENGTH]` in msec(!) since start

    .desc
    :   `[CELL: 1xMARKERLENGTH of STRINGs]` marker descriptors

    .current\_time
    :   `[DOUBLE]` time of last acquired sample since start in msec

data.buffer
:   struct array with fields:
    .size
    :   Size of the buffer (in time dimension) in unit samples.
    .x
    :   `[DOUBLE: TIMExCHANNELS]` storing the recent continuous signals
        as a ring buffer. This buffer needs to be large enough (set by
        bbci.cont\_proc.buffer\_size) to hold segments from which
        features are calculated, see bbci.feature.ival.

    .ptr
    :   Points to the last stored sample (in time dimension).
    .clab
    :   Labels of the channels in the buffer.
    .fs
    :   sampling rate
    .use\_state
    :   `[BOOLEAN: nFcns]` For each function in bbci.cont\_proc.fcn this
        flag indicates whether it uses state variables.

    .state
    :   `CELL` used to store states of the bbci.cont\_proc.fcn functions

    .current\_time
    :   `[DOUBLE]` time of last acquired sample since start in msec

data.feature
:   `CELL` of struct with obligatory fields (there may be more):

    .x
    :   . typical other fields
    .clab
    :   Labels of the channels in the features.

data.classifier
:   struct array with fields:
    .x
    :   .

data.control
:   Control signal to be sent to the application via UDP (or passed as
    argument in a direct call of a Matlab feedback). struct array with
    fields:
    .lastcheck
    :   Time of the last condition check wrt. to this control function
    .memo
    :   Field that can be used by control functions to store
        'persistent' variables.
    .packet
    :   Cell specifying a variable/value list; \*Alternatively, we could
        implement it as:\* Structure, each field refers to a variable
        name and its value is the value of that variable that is to be
        send to the application

data.log
:   Information needed for logging

    .fid
       :   `file ID of log file (or 1 is bbci.log.output=='screen'), if bbci.log.output=='screen&file', this is a vector [1 file_id].`

    .filename
       :   name of the log file (if bbci.log.output is 'file' or
        -   'screen&file')

