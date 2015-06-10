# Basic Data Structures of the BBCI Toolbox

## Table of Contents

- [`cnt`](#Cnt) - _Data structure holding the continuous signals_
- [`mrk`](#Mrk) - _Marker structure defining certain events_
- [`epo`](#Epo) - _Segmented signals (epochs)_
- [`mnt`](#Mnt) - _Montage structure defining the electrode layout for scalp and grid plots_

## `cnt` - Continuous signals  <a id="Cnt"></a>

The structure holding continuous (i.e., not epoched) EEG signals is denoted by `cnt`.

**`cnt`** | **is a structure with the following fields:**
--------- | ---------------------------------------------
`.fs`     |   sampling rate [samples per second]
`.x`      |   multichannel signals (`DOUBLE [T #channels]`)
`.clab`   |   channel labels (`CELL {1 #channels}`) there may be additional information in other fields, but these are all optional


## `mrk` - Event markers   <a id="Mrk"></a>

The structure holding marker (or event) information is denoted by `mrk`. Using
this structure you can segment continuous EEG signals into epochs by the
function `proc_segmentation`.

**`mrk`**    | **is a structure with the following fields:**
------------ | ---------------------------------------------
`.time`      | defines the time points of events in msec (`DOUBLE [1 #events]`)
`.y`         | class labels (`DOUBLE [#classes #events]`)
`.className` | class names (`CELL {1 #classes}`)
`.event`     | structure of further information; each field of `mrk.event` provides information that is specified for each event, given in arrays that index the events _in their first dimension_. This is required such that functions like `mrk_selectEvents` can work properly on those variables.

This structure can optionally have more fields, with are transfered to the `epo`
structure, when creating epochs. See also the note in the description of the
`epo` structure and the help of the function `proc_segmentation`.


## `epo` - Segmented signals  <a id="Epo"></a>

The structure holding epoched EEG signals (i.e., a series of short-time windows
of equal length) is denoted by `epo`. (This structure is not resticted to time
domain signals, although it is suggested by some notions, e.g. the field `.t`).

**`epo`**    | **is a structure with the following fields:**
------------ | ---------------------------------------------
`.fs`        | sampling rate [samples per second]
`.x`         | multichannel signals (`DOUBLE [T #channels #epochs]`) where `T` is the number of samples within one epoch
`.clab`      | channel labels (`CELL {1 #channels}`)
`.y`         | class labels (`DOUBLE [#classes #epochs]`)
`.className` | class names (`CELL {1 #classes}`)
`.t`         | time axis (`DOUBLE [1 T]`)
`.event`     | structure of further information; each field of `epo.event` provides information that is specified for each event, given in arrays that index the events **in their first dimension**. This is required such that functions like `epo_selectEpochs` can work properly on those variables.
`.mrk_info`  | structure for other additional information copied from `mrk`
`.cnt_info`  | structure for additional information copied from `cnt`

## `mnt` - The electrode montage   <a id="Mnt"></a>

The electrode montage structure, denoted by `mnt`, holds the information of the
spatial arrangement of the electrodes on the scalp (for plotting scalp
topographies) and the arrangement of subplot axes for multi-channel plots.

**`mnt`**       | **is a structure with the following fields:**
--------------- | ---------------------------------------------
`.clab`         | channel labels (`CELL {1 #channels}`)
`.x`            | x-position of the electrode for scalp maps (`DOUBLE [1 +channels]`)
`.y`            | y-position of the electrode for scalp maps (`DOUBLE [1 +channels]`)
                | **further optional fields are required for multichannel plots:**
`.box`          | positions of subplot axes for multichannel plots (`DOUBLE [2 #channels]` or `[2 #channels+1]`; the first row holds the horizontal, and the second row the vertical positions. The optional last column specifies the position of the legend
`.box_sz`       | size of subplot axes for multichannel plots (`DOUBLE [2 #channels]` or `[2 #nchannels+1]`), corresponding to `.box`. The first row holds the width, the second row the height
`.scale_box`    | position of subplot for the scale (`DOUBLE [2 1]`)
`.scale_box_sz` | size of subplot for the scale (`DOUBLE [2 1]`)
