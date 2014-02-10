---

# A Detailed Description of the Data Structes in BBCI Online

---

In `bbyi_apply` there are two central structures.

1.  The `bbci` structure specifies WHAT should be done and HOW: data
    acquisition, processing, feature extraction, classification,
    determining the control signal, and calling the application. It is
    the input to `bbci_apply`.
2.  The `data` structure is used to store the acquired signals, and
    various steps of processed data, as well as some state information.
    It is the working variable of `bbci_apply`.

You can also type  
> `help bbci_apply_structures`  
to get this information about the two data structure `bbci` and `data`.


## Structure BBCI


The defaults are set in `bbci_apply_setDefaults`.

**`bbci.source`**:   Defines the sources for acquiring signals. struct array with fields:

<table border="1" > <tr> <td> .acquire_fcn </td><td> [STRING, default 'acquire_bv']</td></tr>
<tr> <td> .acquire_param </td><td> [CELL ARRAY, default {}]: parameters to acquire_fcn</td></tr>  
<tr> <td> .min_blocklength </td><td> [DOUBLE, default 40]: minimum blocklength [msec] that should be acquired before dat is passed to further processing (in bbci_apply_setDefaults a variant .min_blocklength_sa is   added for convenience.)</td></tr>  
<tr> <td> .clab </td><td> [CELL ARRAY of STRING, default {'*'}]</td></tr>  
<tr> <td>  .log </td><td> see bbci.log. This field specifies, whether source-specific
        information should be logged (which is reporting when the length
        of an acquired block is larger than .min_blocklength)</td></tr>  
<tr> <td> .acquire_param </td><td> [CELL ARRAY, default {}]: parameters to acquire_fcn</td></tr> 
</table>


**`bbci.marker`**:   Defines how the acquired markers are stored. struct with fields:
<table border="1" > 
<tr> <td>  .queue_length </td><td> Specifies how many markers are stored in the marker queue (see
        data.marker). The markers in the queue are available for queries
        and evaluating conditions, see bbci_apply_queryMarker.</td></tr>
</table>


**`bbci.signal`**:   Defines how the continuous signals are preprocessed and stored into the ring buffer. It is a struct array with fields:

<table border="1" >
<tr> <td> .source </td><td>  [DOUBLE, default 1] specifies from which data source (see
        above) this signal is extracted </td></tr>
<tr> <td>  .proc  </td><td> [CELL ARRAY, one cell per proc function, each CELL is either a FUNHANDLE,  or a CELL ARRAY{FUNC, PARAM}, where FUNC is a FUNHANDLE and PARAM is a CELL ARRAY of parameters to the function; default {}]  </td></tr>    
<tr> <td>   .buffer_size  </td><td> [DOUBLE,default 10000] in msec  </td></tr>
<tr> <td>  .clab  </td><td>  [CELL ARRAY of STRING, default {'*'}] The subset of
        bbci.source.clab that is used by the signal.  </td></tr>
</table>
        

**`bbci.feature`**:   Defines extraction of features from continuous signals. struct array  with fields:

<table border="1" >
<tr> <td>  .signal  </td><td>   [vector of DOUBLE, default 1] specifies from which signal (see
        above) this feature is extracted </td></tr>
<tr> <td>   .ival  </td><td>  vector [start_msec end_msec] specifies the size of the epoch </td></tr>  
<tr> <td> .proc  </td><td>    [CELL ARRAY, one cell per proc function, each CELL is either a FUNHANDLE, or a CELL ARRAY{FUNC, PARAM}, where FUNC is a FUNHANDLE and PARAM is a CELL ARRAY of parameters to the function; default {}]  </td></tr>    
</table>


**`bbci.classifier`**:   Specifies classification (model and parameters). struct array with fields:
 <table border="1" >
 <tr> <td>   .feature </td><td>   [vector of DOUBLE, default 1] specifies to which feature this
        classifier is applied
 </td></tr>
<tr> <td>  .apply_fcn  </td><td> FUNHANDLE  </td></tr> 
<tr> <td>  .C  </td><td> [STRUCT] the trained classifier (which is passed to the apply
        function)  </td></tr>
</table>


**`bbci.control`**:   Defines how to translate the classifier output (and given the event marker) into the control signal. struct array with fields:
    
 <table border="1" >
 <tr> <td> .classifier  </td><td> [vector of DOUBLE, default 1] specifies which classifier
        output (see above) is translated to a control signal </td></tr>   
<tr> <td>   .fcn </td><td>   [FUNHANDLE, default ]  </td></tr>
 <tr> <td>  .param   </td><td>  (if ~isempty(bbci.control.fcn))  </td></tr>
<tr> <td> .condition  </td><td>  defines the events which evokes the calculation of a control
        signal: [] means evaluate control signal for each data packet
        that was acquired
        <table border="1" >
        <tr> <td> .marker  </td><td> CELL of STRINGs (??or rather [vector of DOUBLE]??)
            specifying the markers that evoke the calculation of a control signal (if interval) </td></tr>
         <tr> <td>  .interval  </td><td>  [DOUBLEin msec] (does this option make sense?)  </td></tr>
        <tr> <td>  .overrun  </td><td>   [DOUBLE in msec] after .marker this amount of signals must  -   have been required (such that epochs of all required
            -   feature can be obtained) </td></tr>
          </td></tr>
            </table>
</table>
   

**`bbci.feedback`**:   Defines where and how the control signal is sent. struct array with fields:

<table border="1" > 
<tr> <td> .control </td><td>   [vector of DOUBLE, default 1] specifies which control signals
        (see above) are send to the feedback application  </td></tr>
<tr> <td>   .receiver </td><td>   'matlab', 'pyff', 'screen', or 'tobi-c'` </td></tr>
</table>


**`bbci.adaptation`**: Specifies whether, what and how adaptation should be done. struct with fields

<table border="1" > 
<tr> <td>  .active  </td><td>  BOOL whether adaptation is switched on </td></tr>
<tr> <td>   .fcn  </td><td>  FUNHANDLE adaptation function. </td></tr>
<tr> <td>   .param </td><td>   CELL parameters that are passed to the adaptation.fcn </td></tr>
<tr> <td>    .log </td><td> see bbci.log. This field specifies, whether information about
        adaptation should be logged </td></tr>
</table>


**`bbci.quit_condition`**: Defines the condition when bbcu_apply should quit. struct with fields
    
<table border="1" > 
<tr> <td>   .running_time </td><td>  [DOUBLE in sec, default inf]  </td></tr>
<tr> <td>  .marker </td><td> [CHAR or CELL ARRAY of CHAR, default]  </td></tr>
</table>    


**`bbci.log`**:   Defines whether and how information should be logged

<table border="1" > 
<tr> <td>  .output  </td><td>  0 (or 'none')  for no logging, or 'screen', or 'file', or
        'screen&file'; 'screen' is default if bbci.feeback.receiver
        is empty, otherwise 0.  </td></tr>
<tr> <td> .filebase  </td><td>  CHAR filename of logfile. May include '$TODAY_DIR' and '$VP_CODE', which are then replaced by the values of the
        respective global variables.  </td></tr>
<tr> <td>  .time_fmt  </td><td> CHAR print format of the time, default '%08.3fms'  </td></tr>
<tr> <td>    .clock  </td><td>  BOOL specifies whether the clock should also be logged,
        default 0.  </td></tr>
<tr> <td>   .classifier  </td><td> BOOL specifies whether the classifer should also be logged,
        default 0.  </td></tr>
</table>


## Structure `data`

Is initialized in `bbci_apply_initData.m`

**`data.source`**:   struct array with fields:

<table border="1" > 
<tr> <td>   .state </td><td> state structure of acquire function  </td></tr>
<tr> <td>  .x </td><td> recent block of acquired data  </td></tr>
<tr> <td>  .fs </td><td> sampling rate  </td></tr>
<tr> <td>  .clab </td><td> CELL of channel labs in source.x (these are selected by
        bbci.source.clab)  </td> number of the last sample in the recent data (source.x) relative
        to the start of bbci_apply </tr>
<tr> <td> .sample_no  </td><td>   </td></tr>
<tr> <td>     .time  </td><td> time of acquisition, i.e. 'sample_no' converted to msec  </td></tr>
</table>

 
**`data.marker`**:   struct with fields:

<table border="1" > 
<tr> <td>  .time  </td><td> [DOUBLE: 1xMARKER.QUEUELENGTH] in msec(!) since start </td></tr>
<tr> <td>   .desc </td><td>  [CELL: 1xMARKERLENGTH of STRINGs] marker descriptors </td></tr>
<tr> <td>  .current_time  </td><td> [DOUBLE] time of last acquired sample since start in msec  </td></tr>
</table>


**`data.buffer`**:   struct array with fields:

<table border="1" > 
<tr> <td>    .size </td><td> Size of the buffer (in time dimension) in unit samples.  </td></tr>
<tr> <td>  .x  </td><td>  [DOUBLE:TIMExCHANNELS]  storing the recent continuous signals
        as a ring buffer. This buffer needs to be large enough (set by
        bbci.cont_proc.buffer_size) to hold segments from which
        features are calculated, see bbci.feature.ival.  </td></tr>
<tr> <td> .ptr  </td><td> Points to the last stored sample (in time dimension)  </td></tr>
<tr> <td>   .clab  </td><td>  Labels of the channels in the buffer.  </td></tr>
<tr> <td>   .fs </td><td> sampling rate  </td></tr>
<tr> <td>    .use_state </td><td>  [BOOLEAN: nFcns] For each function in bbci.cont_proc.fcn this
        flag indicates whether it uses state variables.  </td></tr>
<tr> <td> .state  </td><td>  CELL used to store states of the bbci.cont_proc.fcn functions  </td></tr>
<tr> <td>  .current_time   </td><td> [DOUBLE] time of last acquired sample since start in msec  </td></tr>
</table>


**`data.feature`**: `CELL` of struct with obligatory fields (there may be more):

<table border="1" > 
<tr> <td>   .x </td><td>   typical other fields  </td></tr>
<tr> <td>   .clab </td><td>  Labels of the channels in the features.  </td></tr>
</table>


**`data.classifier`**:   struct array with fields:
<table border="1" > 
<tr> <td>   .x </td><td>classifier output</td></tr>
</table>


**`data.control`**:   Control signal to be sent to the application via UDP (or passed as argument in a direct call of a Matlab feedback). struct array with fields:

<table border="1" > 
<tr> <td>  .lastcheck  </td><td>  Time of the last condition check wrt. to this control function  </td></tr>
<tr> <td>   .memo  </td><td>   Field that can be used by control functions to store
        'persistent' variables. </td></tr>
<tr> <td> .packet  </td><td>   Cell specifying a variable/value list; \*Alternatively, we could
        implement it as:\* Structure, each field refers to a variable
        name and its value is the value of that variable that is to be
        send to the application </td></tr>
</table>


**`data.log`**:   Information needed for logging
<table border="1" > 
<tr> <td>  .fid  </td><td> file ID of log file (or 1 is bbci.log.output=='screen'), if bbci.log.output=='screen&file', this is a vector [1 file_id].  </td></tr>
<tr> <td> .filename  </td><td> name of the log file (if bbci.log.output is 'file' or  -   'screen&file')  </td></tr>
</table>
