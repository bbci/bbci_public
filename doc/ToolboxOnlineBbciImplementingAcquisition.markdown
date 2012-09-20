A Guide for Implementing new Acquisition Functions
--------------------------------------------------

The implementation of new acquisition functions is only necessary if new
hardware is to be used, but which no implementation exists. Note, that
there is an interface to the TOBI signal server (via
`bbci_acquire_sigserv.m`{.backtick}), which already offers access to a
variety of biosignal acquisition hardware. WHO CAN ADD A LIST HERE? LINK
TO WEBSITE?

The function `bbci_apply_acquireData`{.backtick} is called by
`bbci_apply`{.backtick} to get incoming data packets of bio signals.
That function is a wrapper that calls hardware specific subfunctions,
which should be named `bbci_acquire_XYZ`{.backtick} with 'XYZ' being a
specific and compact description of the type of acquisition hardware.
The calling convention for the `bbci_acquire_*`{.backtick} functions is
described in `online/acquisition/Contents.m`{.backtick}. When you have
written a new acuisition function, please, add a short description in
the `Contents.m`{.backtick} file.

The acquisition functions are called in three different modes:
initialization, data fetching, and closing the connection:


~~~~ {#CA-56feaed04ca66e79c4f5c267c8b9261547919d1c dir="ltr" lang="en"}
%  state= bbci_acquire_XYZ('init', <PARAM>)
%  [CNTX, MRKTIME, MRKDESC, state]= bbci_acquire_XYZ(state)
%  bbci_acquire_XYZ('close')
~~~~

**Initialization:** This function has to open the connection with the
acquisition hardware to get information about the configuration. This
information is stored in the variable `state`{.backtick} (STRUCT), that
is used in subsequent calls to get the data. Required fields of the
variable `state`{.backtick} are

<table border="1" > <tbody>
<tr> <td>`state.clab`{.backtick} </td><td> CELL of CHAR holding the channel labels  </td></tr>
<tr> <td> `state.fs`{.backtick}  </td><td> DOUBLE holding the sampling rate</td> </tr>
</tbody></table>

Optional parameters can be specified as further arguments in the
initialization. There are no strict rules for these parameters.
Formally, the convention of the BBCI toolbox for specifying optional
parameters should be followed (property/value list or struct). If
functionality is existing in other acqusition function, it would be good
to use the same name for that property (e.g., `fs`{.backtick} for target
fampling rate of subsampling; `filt_b`{.backtick}, `filt_a`{.backtick}
for specifying an IIR filter).

**Data Fetching:** In this mode, the `state`{.backtick} is passed as
input variable and returned as fourth output variable. If the connection
to the acquisition hardware was closed (externally), the field
`state.running`{.backtick} has to be set to `0`{.backtick}. The acquired
data is returned in the first three output arguments.

<table border="1"  f> 
<tr> <td>CNTX </td><td> `DOUBLE`{.backtick} [Time Channels] signals </td></tr>
<tr> <td> MRKTIME </td><td>   `DOUBLE`{.backtick} [1 nMarkers] position [msec] within data block. A
marker occurrence within the first sample would give 
`MRKTIME= 1/STATE.fs`{.backtick}. </td></tr>
 <tr> <td> MRKDESC   </td>
    <td>  <table border="1" > <tbody>
    <tr> <td> `CELL`{.backtick} {1 nMarkers} descriptors like 'S 52', **OR** </td></tr>
     <tr> <td> `DOUBLE`{.backtick} [1 nMarkers] numeric representation of markers </td>  </tr>
     </tbody></table> 
</td> </tr>
</table>

Whether a *symbolic* or a *numeric* representation of markers is used,
is a matter of taste. If possible, the numeric representation is to be
prefered, since it is computationally cheaper. However, the symbolic
format is more flexible, so the BBCI online system allows both kinds of
representations.

**Closing:** Not much to say here. Most data acquisition is realized
over an connection like TCP/IP that should be closed when acquisition is
finished.
