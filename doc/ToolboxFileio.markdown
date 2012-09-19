Documentation: Functions for reading and writing data files
===========================================================

* * * * *

**IN CONSTRUCTION**

* * * * *

Location of Data Files
----------------------

The data that we record (using the
Brain Vision Recorder)
is stored in raw format in a subdirectory of EEG\_RAW\_DIR (global
variable). The naming scheme for the subdirectories is
Subject\_yy\_mm\_dd, e.g., Gabriel\_02\_11\_24. One data set in
BrainVision generic
data format consists for three files: (1) a binary data file, extension
.eeg, (2) a header file holding information on the settings of the
recording as sampling rate, used channels, etc., extension .vhdr, and
(3) a marker file, extension .vmrk. Data we receive in other formats
from other labs are stored in a subdirectory of EEG\_IMPORT\_DIR.

Preprocessed data is stored in matlab format in a subdirectory of
EEG\_MAT\_DIR. The name of this subdirectory should be the same as that
of the raw data. Typically the data is stored in a version which is just
downsampled and in a version which is filtered and downsampled for
display purpose. The former fi le is called like the original data, and
the latter has the appendix \_display. Each matlab file should include
the variables cnt, mrk and mnt.

Loading Data which is in the Original Generic Data Format
---------------------------------------------------------

For the EEG experiments, that we record at our lab, we store data in
"preprocessed" formats. One version is just
downsampled, which can also be done when reading the original data
(using readGenericEEG). But loading the preprocessed data (using
eegfile\_loadMatlab) has the advantage that the markers are already
brought to a nice format. If you want to load data in this convenient
way.
Otherwise read on in this section.


~~~~ {#CA-972a653370335018662459f32109e193db7457e7 dir="ltr" lang="en"}
   1 cnt = readGenericEEG(file, [clab, fs, from, maxlen]);
   2 
~~~~

This function can be used to load data which is in
BrainVision 's generic
data format. So far it is quite constrained to take only specific
variants of the general generic data format. Data must be multiplexed
and in the binary format INT16. (To read data in binary format float
there is the function readGenericEEG\_float: should be integrated in one
function?) To determine the available channels or the length of the data
use the function readGenericHeader.

<table border="1"><tbody>
<tr>  <td>file </td> <td> is taken relative to EEG\_RAW\_DIR, unless it starts with the character
'/'. (Under Windows the condition for an absolute pathname is that the
second character is a ':'.) </td></tr>
<tr>  <td> clab </td> <td> labels of the channels to be loaded.</td></tr>
<tr>  <td> fs </td> <td> sampling rate to which the original data are to be downsampled. The
default value is 100. This works only when fs is a divisor of the
original sampling rate. To read data in the original sampling rate use
'raw'. </td></tr>
<tr>  <td> from </td> <td> is the start in msec from which data is to be read.</td></tr>
<tr>  <td> maxlen </td> <td> is the maximum length of data in msec to be read.</td> </tr>
</tbody></table>

Output:

<table border="1"><tbody>
<tr>  <td>cnt  </td> <td> struct of continous EEG data. </td> </tr>
</tbody></table>

See also: eegfile\_loadMatlab, readGenericHeader, readGenericMarkers.


~~~~ {#CA-287e105aef0b0d8348748e17d43813daa8496739 dir="ltr" lang="en"}
   1 [clab, scale, fs, endian, len] = readGenericHeader(file);
   2 
~~~~

This function is used by readGenericEEG. It can also be called directly
to determine the original sampling rate, the length of the signals and
the recorded channels.

<table border="1"><tbody>
<tr>  <td>file </td> <td> is the name of the header file (without the extension .vhdr). The same applies as for read readGenericEEG.</td> </tr>
</tbody></table>

Output:

<table border="1"><tbody>
<tr>  <td>clab </td>  <td> cell array of electrode labels.</td> </tr>
<tr>  <td> scale </td>  <td> vector specifying the scaling factor for each channel by which each
sample value (in INT16 format) has to be multiplied to obtain the µV value.</td> </tr>
<tr>  <td> fs </td>  <td> sampling rate in which the signals are stored.</td> </tr>
<tr>  <td> endian </td>  <td> big ('b') or little ('l') endian byte order. </td> </tr>
<tr>  <td> len </td>  <td> length of the EEG signals in seconds.</td> </tr>
</tbody></table>



~~~~ {#CA-cadffeff5d6d757081a8d6a680e4ac3cd74b26bb dir="ltr" lang="en"}
   1 Mrk = readGenerikMarkers(file, [outputStructArray]);
   2 
~~~~

This function reads all markers of
BrainVision 's generic
data format. If you are only interested in 'Stimulus' and 'Response'
markers, readMarkerTable is your friend. Note: this function returns the
markers in the original sampling rate. In contrast, readMarkerTable
returns markers by default resampled to 100 Hz.



<table border="1"><tbody>
<tr>  <td>file </td> <td> is the name of the header file (without the extension .vmrk). The same
applies as for readGenericEEG.</td> </tr>
<tr>  <td> outputStructArray </td> <td> specifies the output format, default 1. If false the output is a struct
of arrays, not a struct array.</td> </tr>
</tbody></table>


Output:

<table border="1"><tbody>
<tr>  <td>Mrk </td> <td> struct array of markers with fields type, desc, pos, length, chan, time
which are defined in the BrainVision  generic data format, see the comment lines in any \*.vmrk marker file. </td> </tr>
<tr>  <td> fs </td> <td> sampling rate, as read from the corresponding header file.</td> </tr>
</tbody></table>

See also: readMarkerTable, readGenericHeader.


~~~~ {#CA-dadbb18b50a7147fdfaacace0cc683e49c3cf981 dir="ltr" lang="en"}
   1 mrk = readMarkerTable(file, [fs=100, markerTypes, flag]);
   2 
~~~~

This function reads all 'Stimulus' and 'Response' markers from the
header file. For reading markers of other types you can use
readAlternativeMarker. See also readMarkerTableArtifacts for reading the
marker file of an artifact measurement (with annotated artifacts), and
readSegmentBorders. A general function that reads all marker information
of the BrainVision
generic data format is readGenericMarkers.

<table border="1"><tbody>
<tr>  <td> file </td>  <td> is the name of the header file (without the extension .vmrk). The same
applies as for readGenericEEG.</td></tr>
<tr>  <td> fs </td>  <td> sampling rate for the returned marker structure. The default value is 100.</td></tr>
<tr>  <td> markerTypes </td>  <td> read only markers of this type, default {'Stimulus','Response'}. </td></tr>
<tr>  <td> flag </td>  <td> a vector of the same length as markerTypes which defines the sign of the
marker values (in the type-of-event field toe of the returned marker
structure). The default is [1 -1], i.e., stimulus markers give positive
marker numbers and response markers give negative marker numbers.</td> </tr>
</tbody></table>

Output:

<table border="1"><tbody>
<tr>  <td>mrk </td>  <td> struct of EEG marker </td> </tr>
</tbody></table>

Saving and Loading EEG Data in Matlab Format
--------------------------------------------


~~~~ {#CA-58b77076efad8e34c08fced0a64be5edc23d5385 dir="ltr" lang="en"}
   1 [dat, mrk, mnt] = eegfile_loadMatlab(file, [opt]);
   2 [var1, var2, ...] = eegfile_loadMatlab(file, opt);
   3 
~~~~

This function loads EEG data, that was stored using eegfile\_saveMatlab.
It can also concat a series of such files.

<table border="1"><tbody>
<tr>  <td> file </td>  <td> name of data file, or cell array of file names. In the latter case all
files are concatenated. Each file name is taken relative to opt.path
(see below), unless it starts with the character '/'. (Under Windows the
condition for an absolute pathname is that the second character is a
':').</td> </tr>
</tbody></table>

The options struct or property/value list can have the
following properties:

<table border="1"><tbody>
<tr>  <td>.clab </td> <td> Channel labels (cell array of strings) for loading a subset of all
channels. Default 'ALL' means all available channels. See function
chanind for valid formats. In case opt.clab is not 'ALL' the electrode
montage mnt is adapted automatically.</td> </tr>
<tr>  <td>

.vars
</td> <td>
Variables (cell array of strings) which are to be loaded, default
'dat','mrk','mnt'. The names 'dat', 'cnt' and 'epo' are treated equally
and all match the data structure.</td> </tr>
<tr>  <td> .path </td> <td> In case file does not include an absolute path, opt.path is prepended to
file. Default EEG\_MAT\_DIR (global variable).</td> </tr>
</tbody></table>

Output:

<table border="1"><tbody>
<tr>  <td>dat </td> <td> structure of continuous or epoched signals</td></tr>
<tr>  <td> mrk </td> <td> marker structure</td></tr>
<tr>  <td> mnt </td> <td> electrode montage structure</td></tr>
<tr>  <td> varx </td> <td> variables as requested by opt.vars. </td> </tr>
</tbody></table>

Example:


~~~~ {#CA-1a59257e52dfc44079b53ad926ee67405d75512c dir="ltr" lang="en"}
   1 >> file= 'Gabriel_03_05_21/selfpaced2sGabriel';
   2 >> [cnt,mrk,mnt]= eegfile_loadMatlab(file);
   3 >> %% or just to load variables 'mrk' and 'mnt':
   4 >> [mrk,mnt]= eegfile_loadMatlab(file, {'mrk','mnt'});
   5 >> %% or to load only some central channels
   6 >> [cnt, mnt]= eegfile_loadMatlab(file, 'clab','C5-6', 'vars',{'cnt','mnt'});
   7 
~~~~


~~~~ {#CA-005d539e95d93de7c27a52fe3983407875fdc79d dir="ltr" lang="en"}
   1 eegfile_saveMatlab(file, dat, mrk, mnt, [opt]);
   2 
~~~~

This functions saves (potentially preprocessed) EEG data along with
structures defining markers and a display montage. Optionally additional
variable can also be stored.

|| file|| is the name of the file. The same applies as for
eegfile\_loadMatlab.||


<table border="1"><tbody>
<tr>  <td>dat </td> <td> structure of EEG data, may be continuous or epoched.</td></tr>
<tr>  <td> mrk </td> <td> marker structure</td></tr>
<tr>  <td> mnt </td> <td> electrode montage structure</td> </tr>
</tbody></table>

The options struct or property/value list can have the
following properties:

<table border="1"><tbody>
<tr>  <td> .path </td> <td>  In case file does not include an absolute path, opt.path is prepended to
file. Default EEG\_MAT\_DIR (global variable). </a></td> </tr>
<tr>  <td> .channelwise </td> <td>  If true, signals are saved channelwise. This is an advantage for big
files, because it allows to load selected channels. </a></td> </tr>
<tr>  <td> .format </td> <td>  'double', 'float', 'int16', or 'auto' (default). In 'auto' mode, the
function tries to find a lossless conversion of the signals to INT16
(see property .resolution\_list). If this is possible .format is set to
'INT16', otherwise it is set to 'DOUBLE'. </a></td> </tr>
<tr>  <td> .resolution </td> <td>  Resolution of signals, when saving in format INT16. (Signals are divided
by this factor before saving.) The resolution may be selected for each
channel individually, or globally for all channels. In the 'auto' mode,
the function tries to find for each channel a lossless conversion to
INT16 (see property .resolution\_list). For all other channels the
resolution producing least information loss is chosen (under the
resolutions that avoid clipping). Possible values: (1) 'auto' (default),
(2) numerical scalar, or (3) numerical vector of length 'number of
channels' (i.e., length(dat.clab)).</a></td> </tr>
<tr>  <td> .resolution\_list </td> <td> Vector of numerical values. These values are tested as resolutions to
see whether lossless conversion to INT16 is possible. Default [1 0.5
0.1]. </a></td> </tr>
<tr>  <td> vars </td> <td>  Additional variables that should be stored. opt.vars must be a cell
array with a variable name / variable value structure, e.g., {'Mrk',Mrk,
'blah',blah} when Mrk and blah are the variables to be stored.</td> </tr>
</tbody></table>


Exporting Data to the Generic Data Format
-----------------------------------------



~~~~ {#CA-ccb8770622fdfe751a966f859a5ea7b39c9b92fd dir="ltr" lang="en"}
   1 writeGenericData(dat, [mrk, scale]);
   2 
~~~~


<table border="1"><tbody>
<tr>  <td>dat</td>  <td>structure of continuous or epoched EEG data.</td></tr>
<tr>  <td>mrk </td> <td>struct of EEG marker </td> </tr>
<tr>  <td>scale</td> <td> scaling factor used in the generic data format
 to bring data from the INT16 range -32768 to 32767 to µV values. This 
is implemented as a division by the scaling factor before saving the 
signals. Individual scaling factors may be specified for each channel in
 a vector, or a global scaling as scalar, default is 0.1 (i.e., signal 
range is -3276.8 to 3276.7 µV). Use scale= max(abs(cnt.x))'/32768 to 
achive best resolution (least information loss in INT16 conversion) 
without clipping. </td> </tr>
</tbody></table>
