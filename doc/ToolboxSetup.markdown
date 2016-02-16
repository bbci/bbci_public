# Documentation: Setting up and Starting the Toolbox


## Getting the BBCI Toolbox

There are two ways to get the BBCI Toolbox:

1. get a copy of the latest snapshot, or
2. checking it out from the GIT repository.

Variant 2 gives the possibility to keep up-to-date with the most recent version,
while snapshots will be provided only after larger updates.

In any case, it is important that you do not modify functions within the
toolbox. Your changes will get lost after updating, unless you take great care
to transfer them. If you need to change toolbox functions, it is recommended
that you make a copy of the functions to another folder that you put in higher
priority into the matlab search path and modify functions there.

If you want to run the demos of the toolbox you also need to download the demo
datasets (sorry: large files). 


### Getting the latest snapshot of the BBCI Toolbox

Download this [archive](https://github.com/bbci/bbci_public/archive/master.zip)
and unzip it at an appropriate place.


### Checking out the GIT repository of the BBCI Toolbox

The GIT repository is available at github: https://github.com/bbci/bbci_public


#### Linux

```bash
mkdir ~/git
cd ~/git
git clone https://github.com/bbci/bbci_public bbci_public
```

If you plan to work with our Open Source Framework Pyff for Stimulus
Presentation or Feedbacks, you need to get the Pyff repository separately:

```bash
git clone git://github.com/bbci/pyff
```


#### Mac OS

Open the terminal. If you cannot find the terminal either go to your Desktop or
open Finder. Then click on Go -> Utilities. Then type in

```bash
mkdir ~/git
cd ~/git
git clone https://github.com/bbci/bbci_public bbci_public
```

#### Windows

Git for Windows can be downloaded from here:

> http://msysgit.github.io/

Installing Git for Windows will add git-related options to the context menu of
the Windows Explorer (i.e. you will see these options when you right-click on a
folder).

After installing Git for Windows, open the folder in which you would like to
store the BBCI Toolbox. In this folder, right-click to open the context menu and
choose the option 'Git Bash'. A terminal window (bash) will open. In the
terminal window type

```bash
git clone https://github.com/bbci/bbci_public
```

Alternatively, you can use the GUI provided by Git for Windows to clone the
repository. The GUI appears when you choose Git GUI from the context menu.


## Getting data for the demos

There are files in raw data format (as stored by the EEG recording software,
Brain Vision Recorder in this case), and files that have been converted to
Matlab format already. This typically involves already some kind of
preprocessing (e.g., low-pass filtering, subsampling), and the definition of
classes based on markers. You should dedicate one directory for data of the BBCI
Toolbox, e.g., `~/data` under Linux and `d:\data` under Windows and unzip the
following archives there, such that subfolders `demoRaw` and `demoMat` are
created in your data folder.

* [dataRaw](http://doc.ml.tu-berlin.de/bbci/ToolboxData/demoRaw.zip)
* [dataMat](http://doc.ml.tu-berlin.de/bbci/ToolboxData/demoMat.zip)


## Starting the Toolbox

Let us assume the Matlab variable `MyToolboxDir` holds the path to the BBCI
Toolbox. That could be `'d:\git\bbci_public'` under Windows and
`'~/git/bbci_public'` under Linux. Furthermore, you should have one dedicated
folder for data. Let's assume this folder is in the Matlab variable
`'MyDataDir'`. That could be `'d:\data'` under Windows. For running the demos,
you should have herein the subfolders `demoRaw` and `demoMat` from above.
Moreover, it is convenient to have a subfolder `tmp` in the data directory. Then
you can startup the BBCI Toolbox like this:

```matlab
>> cd(MyToolboxDir);
>> startup_bbci_toolbox('DataDir', MyDataDir);
```

If you want to define a different folder for temporary files, you can do it like
this (to define `/tmp/` as temporary folder:

```matlab
>> cd(MyToolboxDir);
>> startup_bbci_toolbox('DataDir', MyDataDir, 'TmpDir','/tmp/');
```

There are more options in `startup_public_bbci`, that should be described here.
Until then, you have to inspect to code to learn about the other possibilities.

To enable all the demos of the toolbox (which are in the folders `demos` and
`online/demos`, you need to run the convert-demos first (only one time - the
converted data is saved in a subfolder of your `demoMat`, see above):

```matlab
>> demo_convert_ERPSpeller
>> demo_convert_MotorImagery
>> demo_convert_NIRSData.
```
