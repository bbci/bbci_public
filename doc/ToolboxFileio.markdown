# Documentation: Functions for reading and writing data files


## Location of Data Files

The data that we record (using the Brain Vision Recorder) is stored in raw
format in a subdirectory of `EEG_RAW_DIR` (global variable). The naming scheme
for the subdirectories is `Subject_yy_mm_dd`, e.g., `Basti_02_11_24`. One data
set in BrainVision generic data format consists for three files: (1) a binary
data file, extension .eeg, (2) a header file holding information on the settings
of the recording as sampling rate, used channels, etc., extension .vhdr, and (3)
a marker file, extension .vmrk. Data we receive in other formats from other labs
are stored in a subdirectory of `EEG_IMPORT_DIR`.

Preprocessed data is stored in matlab format in a subdirectory of `EEG_MAT_DIR`.
The name of this subdirectory should be the same as that of the raw data.
Typically the data is stored in a version which is just downsampled and in a
version which is filtered and downsampled for display purpose. The former fi le
is called like the original data, and the latter has the appendix `_display`.
Each matlab file should include the variables cnt, mrk and mnt.


## Loading Data which is in the Original Generic Data Format

For the EEG experiments, that we record at our lab, we store data in
"preprocessed" formats. One version is just downsampled, which can also be done
when reading the original data (using readGenericEEG). But loading the
preprocessed data (using eegfile_loadMatlab) has the advantage that the markers
are already brought to a nice format. If you want to load data in this
convenient way. Otherwise read on in this section.

```matlab
cnt = readGenericEEG(file, [clab, fs, from, maxlen]);
```

This function can be used to load data which is in BrainVision's generic data
format. So far it is quite constrained to take only specific variants of the
general generic data format. Data must be multiplexed and in the binary format
INT16. (To read data in binary format float there is the function
`readGenericEEG_float`: should be integrated in one function?) To determine the
available channels or the length of the data use the function
`readGenericHeader`.

| Field    	| Description                                                                                                                                                                                                         	|
|----------	|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------	|
| `file`   	| is taken relative to EEG_RAW_DIR, unless it starts with the character '/'. (Under Windows the condition for an absolute pathname is that the second character is a ':'.)                                            	|
| `clab`   	| labels of the channels to be loaded.                                                                                                                                                                                	|
| `fs`     	| sampling rate to which the original data are to be downsampled. The default value is 100. This works only when fs is a divisor of the original sampling rate. To read data in the original sampling rate use 'raw'. 	|
| `from`   	| is the start in msec from which data is to be read.                                                                                                                                                                 	|
| `maxlen` 	| is the maximum length of data in msec to be read.                                                                                                                                                                   	|

Output:

| Field 	| Description                   	|
|-------	|-------------------------------	|
| `cnt` 	| struct of continous EEG data. 	|

See also: `eegfile_loadMatlab`, `readGenericHeader`, `readGenericMarkers`.

```matlab
[clab, scale, fs, endian, len] = readGenericHeader(file);
```

This function is used by `readGenericEEG`. It can also be called directly to
determine the original sampling rate, the length of the signals and the recorded
channels.


| Field  	| Description                                                                                                 	|
|--------	|-------------------------------------------------------------------------------------------------------------	|
| `file` 	| is the name of the header file (without the extension .vhdr). The same applies as for read readGenericEEG.  	|

Output:

| Field    	| Description                                                                                                                                     	|
|----------	|-------------------------------------------------------------------------------------------------------------------------------------------------	|
| `clab`   	| cell array of electrode labels.                                                                                                                 	|
| `scale`  	| vector specifying the scaling factor for each channel by which each sample value (in INT16 format) has to be multiplied to obtain the µV value. 	|
| `fs`     	| sampling rate in which the signals are stored.                                                                                                  	|
| `endian` 	| big ('b') or little ('l') endian byte order.                                                                                                    	|
| `len`    	| length of the EEG signals in seconds.                                                                                                           	|


```matlab
Mrk = readGenerikMarkers(file, [outputStructArray]);
```

This function reads all markers of BrainVision's generic data format. If you are
only interested in 'Stimulus' and 'Response' markers, `readMarkerTable` is your
friend. Note: this function returns the markers in the original sampling rate.
In contrast, `readMarkerTable` returns markers by default resampled to 100 Hz.


| Field               | Description                                                                                             |
|---------------------|---------------------------------------------------------------------------------------------------------|
| `.file`             | is the name of the header file (without the extension .vmrk). The same applies as for `readGenericEEG`. |
| `outputStructArray` | specifies the output format, default 1. If false the output is a struct of arrays, not a struct array.  |


Output:

| Field 	| Description                                                                                                                                                                         	|
|-------	|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------	|
| `mrk` 	| struct array of markers with fields type, desc, pos, length, chan, time which are defined in the BrainVision,generic data format, see the comment lines in any \*.vmrk marker file. 	|
| `fs`  	| sampling rate, as read from the corresponding header file.                                                                                                                          	|

See also: `readMarkerTable`, `readGenericHeader`.


```matlab
mrk = readMarkerTable(file, [fs=100, markerTypes, flag]);
```

This function reads all 'Stimulus' and 'Response' markers from the header file.
For reading markers of other types you can use `readAlternativeMarker`. See also
`readMarkerTableArtifacts` for reading the marker file of an artifact
measurement (with annotated artifacts), and `readSegmentBorders`. A general
function that reads all marker information of the BrainVision generic data
format is `readGenericMarkers`.


| Field         	| Description                                                                                                                                                                                                                                                                             	|
|---------------	|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------	|
| `file`        	| is the name of the header file (without the extension .vmrk). The same applies as for readGenericEEG.                                                                                                                                                                                   	|
| `fs`          	| sampling rate for the returned marker structure. The default value is 100.                                                                                                                                                                                                              	|
| `markerTypes` 	| read only markers of this type, default {'Stimulus','Response'}.                                                                                                                                                                                                                        	|
| `flag`        	| a vector of the same length as markerTypes which defines the sign of the marker values (in the type-of-event field toe of the returned marker structure). The default is [1 -1], i.e., stimulus markers give positive marker numbers and response markers give negative marker numbers. 	|


Output:

| Field 	| Description          	|
|-------	|----------------------	|
| `mrk` 	| struct of EEG marker 	|


## Saving and Loading EEG Data in Matlab Format


```matlab
[dat, mrk, mnt] = eegfile_loadMatlab(file, [opt]);
[var1, var2, ...] = eegfile_loadMatlab(file, opt);
``` 

This function loads EEG data, that was stored using `eegfile_saveMatlab`. It can
also concat a series of such files.


| Field  	| Description                                                                                                                                                                                                                                                                                     	|
|--------	|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------	|
| `file` 	| name of data file, or cell array of file names. In the latter case all files are concatenated. Each file name is taken relative to opt.path (see below), unless it starts with the character '/'. (Under Windows the condition for an absolute pathname is that the second character is a ':'). 	|

The options struct or property/value list can have the following properties:


| Field   	| Description                                                                                                                                                                                                                                          	|
|---------	|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------	|
| `.clab` 	| Channel labels (cell array of strings) for loading a subset of all channels. Default 'ALL' means all available channels. See function `chanind` for valid formats. In case `opt.clab` is not 'ALL' the electrode montage mnt is adapted automatically. 	|
| `.vars` 	| Variables (cell array of strings) which are to be loaded, default 'dat','mrk','mnt'. The names 'dat', 'cnt' and 'epo' are treated equally and all match the data structure.                                                                          	|
| `.path` 	| In case file does not include an absolute path, opt.path is prepended to file. Default EEG_MAT_DIR (global variable).                                                                                                                                	|

Output:

| Field  	| Description                                	|
|--------	|--------------------------------------------	|
| `dat`  	| structure of continuous or epoched signals 	|
| `mrk`  	| marker structure                           	|
| `mnt`  	| electrode montage structure                	|
| `varx` 	| variables as requested by opt.vars.        	|


Example:

```matlab
file= 'Gabriel_03_05_21/selfpaced2sGabriel';
[cnt,mrk,mnt]= eegfile_loadMatlab(file);
%% or just to load variables 'mrk' and 'mnt':
[mrk,mnt]= eegfile_loadMatlab(file, {'mrk','mnt'});
%% or to load only some central channels
[cnt, mnt]= eegfile_loadMatlab(file, 'clab','C5-6', 'vars',{'cnt','mnt'});

eegfile_saveMatlab(file, dat, mrk, mnt, [opt]);
```

This functions saves (potentially preprocessed) EEG data along with structures
defining markers and a display montage. Optionally additional variable can also
be stored.

`file` is the name of the file. The same applies as for `eegfile_loadMatlab`.

| Field | Description                                          |
|-------|------------------------------------------------------|
| `dat` | structure of EEG data, may be continuous or epoched. |
| `mrk` | marker structure                                     |
| `mnt` | electrode montage structure                          |

The options struct or property/value list can have the following properties:

| Field              | Description                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       |
|--------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `.path`            | In case file does not include an absolute path, `opt.path` is prepended to file. Default EEG_MAT_DIR (global variable).                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           |
| `.channelwise`     | If true, signals are saved channelwise. This is an advantage for big files, because it allows to load selected channels.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          |
| `.format`          | 'double', 'float', 'int16', or 'auto' (default). In 'auto' mode, the function tries to find a lossless conversion of the signals to INT16 (see property .resolution_list). If this is possible .format is set to 'INT16', otherwise it is set to 'DOUBLE'.                                                                                                                                                                                                                                                                                                                                                        |
| `.resolution`      | Resolution of signals, when saving in format INT16. (Signals are divided by this factor before saving.) The resolution may be selected for each channel individually, or globally for all channels. In the 'auto' mode, the function tries to find for each channel a lossless conversion to INT16 (see property `.resolution_list`). For all other channels the resolution producing least information loss is chosen (under the resolutions that avoid clipping). Possible values: (1) 'auto' (default), (2) numerical scalar, or (3) numerical vector of length 'number of channels' (i.e., length(dat.clab)). |
| `.resolution_list` | Vector of numerical values. These values are tested as resolutions to see whether lossless conversion to INT16 is possible. Default [1 0.5 0.1].                                                                                                                                                                                                                                                                                                                                                                                                                                                                  |
| `vars`             | Additional variables that should be stored. opt.vars must be a cell array with a variable name / variable value structure, e.g., {'Mrk',Mrk, 'blah',blah} when Mrk and blah are the variables to be stored.                                                                                                                                                                                                                                                                                                                                                                                                       |


## Exporting Data to the Generic Data Format

```matlab
writeGenericData(dat, [mrk, scale]);
```

| Field   | Description                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         |
|---------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `dat`   | structure of continuous or epoched EEG data.                                                                                                                                                                                                                                                                                                                                                                                                                                                        |
| `mrk`   | struct of EEG marker                                                                                                                                                                                                                                                                                                                                                                                                                                                                                |
| `scale` | scaling factor used in the generic data format to bring data from the INT16 range -32768 to 32767 to µV values. This is implemented as a division by the scaling factor before saving the signals. Individual scaling factors may be specified for each channel in a vector, or a global scaling as scalar, default is 0.1 (i.e., signal range is -3276.8 to 3276.7 µV). Use scale= max(abs(cnt.x))'/32768 to achive best resolution (least information loss in INT16 conversion) without clipping. |

