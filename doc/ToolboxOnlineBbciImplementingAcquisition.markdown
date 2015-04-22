# A Guide for Implementing new Acquisition Functions

The implementation of new acquisition functions is only necessary if new
hardware is to be used, but which no implementation exists. Note, that there is
an interface to the TOBI signal server (via `bbci_acquire_sigserv.m`), which
already offers access to a variety of biosignal acquisition hardware. WHO CAN
ADD A LIST HERE? LINK TO WEBSITE?

The function `bbci_apply_acquireData` is called by `bbci_apply` to get incoming
data packets of bio signals. That function is a wrapper that calls hardware
specific subfunctions, which should be named `bbci_acquire_XYZ` with 'XYZ' being
a specific and compact description of the type of acquisition hardware. The
calling convention for the `bbci_acquire_*` functions is described in
`online/acquisition/Contents.m`. When you have written a new acuisition
function, please, add a short description in the Contents.m file.

The acquisition functions are called in three different modes: initialization,
data fetching, and closing the connection:

```matlab
%  state= bbci_acquire_XYZ('init', <PARAM>)
%  [CNTX, MRKTIME, MRKDESC, state]= bbci_acquire_XYZ(state)
%  bbci_acquire_XYZ('close')
```

**Initialization:** This function has to open the connection with the
acquisition hardware to get information about the configuration. This
information is stored in the variable `state` (STRUCT), that is used in
subsequent calls to get the data. Required fields of the variable `state` are

| Field        | Description                             |
|--------------|-----------------------------------------|
| `state.clab` | CELL of CHAR holding the channel labels |
| `state.fs`   | DOUBLE holding the sampling rate        |

Optional parameters can be specified as further arguments in the initialization.
There are no strict rules for these parameters. Formally, the convention of the
BBCI toolbox for specifying optional parameters should be followed
(property/value list or struct). If functionality is existing in other
acquisition function, it would be good to use the same name for that property
(e.g., fs for target fampling rate of subsampling; `filt_b`, `filt_a` for
specifying an IIR filter).

**Data Fetching:** In this mode, the state is passed as input variable and
returned as fourth output variable. If the connection to the acquisition
hardware was closed (externally), the field state.running has to be set to 0.
The acquired data is returned in the first three output arguments.

| Field     | Description                                                                                                                        |
|-----------|------------------------------------------------------------------------------------------------------------------------------------|
| `CNTX`    | DOUBLE [Time Channels] signals                                                                                                     |
| `MRKTIME` | DOUBLE [1 nMarkers] position [msec] within data block. A marker occurrence within the first sample would give MRKTIME= 1/STATE.fs. |
| `MRKDESC` | CELL {1 nMarkers} descriptors like 'S 52', **OR** DOUBLE [1 nMarkers] numeric representation of markers                            |

Whether a *symbolic* or a *numeric* representation of markers is used, is a
matter of taste. If possible, the numeric representation is to be prefered,
since it is computationally cheaper. However, the symbolic format is more
flexible, so the BBCI online system allows both kinds of representations.

**Closing:** Not much to say here. Most data acquisition is realized over an
connection like TCP/IP that should be closed when acquisition is finished.
