---

# Basic Data Structures on the BBCI Toolbox

---

***under construction:***  **TODO: update to new toolbox; reformatting (delete the ugly tables)**

---

## Table of Contents

- [`cnt`](#Cnt) - _Data structure holding the continuous signals_
- [`mrk`](#Mrk) - _Marker structure defining certain events_
- [`epo`](#Epo) - _Segmented signals (epochs)_
- [`mnt`](#Mnt) - _Montage structure defining the electrode layout for scalp and grid plots

---

### `cnt` - Continuous signals  <a id="Cnt"></a>

The structure holding continuous (i.e., not epoched) EEG signals is
denoted by cnt. The following list shows its typical fields.

<table border="1" f>
    <tr> <td> cnt </td><td> Structure of continuous signals </td> </tr>
        <tr> <td>  .x</td><td>The EEG signals as 2-D array of size [T nChannels] with time along the
first and channels along the second dimension.</td></tr>
        <tr>
         <td>.fs</td><td>The sampling rate, unit [samples per second].</td></tr>
        <tr> <td>.clab</td><td>Channel labels, stored as strings in a cell array.</td></tr>
        <tr>
      <td>.title</td><td>Title of the data set (string), used by some visualization functions.
(This field should not be obligatory, but some functions may try access
this field, without prior checking its existance. If so the function
should be corrected.)</td>
    </tr>
</table>


### `mrk` - Event markers   <a id="Mrk"></a>

The structure holding marker (or event) information is denoted by mrk.
Using this structure you can segment continuous EEG signals into epochs
by the function makeEpochs.

<table border="1" >
<tr> <td> mrk </td><td> Structure of marker (or event) information:</td></tr>
<tr> <td> .pos </td><td> Positions of markers in the continuous signals as array of size [1
nEvents]. The unit is sample, i.e., it is relative to the sampling rate
mrk.fs.</td></tr>
<tr> <td> .y </td><td> Class labels of the evnts as 2-D array of size [nClasses nEvents]. The
i-th row indicates class membership with class i (0 means no membership,
1 means membership), see Sec. A.1.</td></tr>
<tr> <td> .className </td><td> Cell array of strings defining names of the classes.</td></tr>
<tr> <td> .fs   </td><td> The sampling rate, unit [samples per second].  </td> </tr>
</table>

This structure can optionally have more fields, with are transfer to the
epo structure, when creating epochs. See also the note in the
description of the epo structure.


### `epo` - Segmented signals  <a id="Epo"></a>

The structure holding epoched EEG signals (i.e., a series of short-time
windows of equal length) is denoted by epo. (This structure is not
resticted to time domain signals, although it is suggested by some
notions, e.g. the field .t).

<table border="1" f>
<tr> <td>epo</td><td> Structure of epoched signals.</td></tr>
<tr> <td> .x</td><td> The EEG epochs as 3-D array of size [T nChannels nEpochs] with time
along the rst, channels along the second, and epochs along the third
dimension. (Thus, an epoch structure holding only one epoch is a special
case of continuous signal structure.)</td></tr>
<tr> <td> .t </td><td> Time line, vector of length T, i.e., the size of the rst dimension of
epo.x. In the frequency domain, this eld holds the frequencies.</td></tr>
<tr> <td> .y </td><td> Class labels of the epochs as 2-D array of size [nClasses nEpochs]. The
i-th row indicates class membership with class i (0 means no
member-ship, 1 means membership)</td></tr>
<tr> <td> .className </td><td> Cell array of strings defining names of the classes.</td></tr>
<tr> <td> .fs </td><td> The sampling rate, unit [samples per second].</td></tr>
<tr> <td> .clab </td><td> Channel labels, stored as strings in a cell array.</td></tr>
 <tr> <td> .title </td><td> Title of the data set (string), used by some visualization functions.
(This field should not be obligatory, but some functions may try access
this field, without prior checking its existance. If so the function
should be corrected.)</td></tr>
 <tr> <td> .file </td><td> The file name (string) of the data set (with absolute path). When the
data set is a concatenation of several files, this field is a cell array
of strings. (This eld is only use by some special functions.)</td>   </tr>
</table>

The epo structure can have more optional fields. They should be copied
by processing functions, see [Sec.4.](https://wiki.ml.tu-berlin.de/wiki/Sec.%204.) When you include fi
elds that specify data ranging over all epochs, be sure that epochs are
indexed by the last dimension and define a (or extend the) field
.indexedByEpochs as cell array holding the names of all such fields.
(Fields .x and .y are automatically treated as indexedByEpochs.) Only
then processing functions like proc_selectEpochs or proc_selectClasses
can work correctly.


### `mnt` - The electrode montage   <a id="Mnt"></a>
The electrode montage structure, denoted by mnt, holds the information
of (1) the spatial arrangement of the electrodes on the scalp and (2)
the arrangement of subplot axes for multi-channel plots.


<table border="1" >
<tr> <td>mnt </td><td>Structure of electrode montage and channel layout: </td></tr>
<tr> <td> .clab </td><td>Channel labels, stored as strings in a cell array. </td></tr>
<tr> <td>.pos_3d </td><td> array of size [3 nChannels] holding the 3-dimensional positions of the
electrode. (Not used by the toolbox so far.) </td></tr>
 <tr> <td> .x </td><td> horizontal coordinates of 2D-projected electrode positions.
('Horizontal' refers to our standard scalp view from the top with nose
up.) </td></tr>
<tr> <td> .y </td><td> vertical coordinates of 2D-projected electrode positions. ('Vertical'
refers to our standard scalp view from the top with nose up.) </td></tr>
<tr> <td> .box </td><td> array of size [2 nChannels] or [2 nChannels+1] defining the positions of
subplot axes for multi-channel views. The first row holds the
horizontal, and the second row the vertical position. The positions have
an arbitrary unit, they are taken relative. The optimal last column
denotes the position of the legend. </td></tr>
<tr> <td> .box_sz </td><td> array of size [2 nChannels] or [2 nChannels+1] defining the size of
subplot axes for multi-channel views. The first row holds the
horizontal, and the seconds row the vertical size. </td></tr>
<tr> <td> .scale_box </td><td> optional field of size [2 1] holding the position of an axes in which
the scale is indicated. </td></tr>
<tr> <td> .scale_box_sz  </td><td> optimal field of size [2 1] defining the size (horizontal and vertical)
of the scale subaxes. </td> </tr>
</table>

