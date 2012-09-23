
* * * * *

Documentation: Setting up and Starting the Toolbox
==================================================

* * * * *

**IN CONSTRUCTION**

* * * * *

Checking out the BBCI SVN
-------------------------

### Linux

    mkdir ~/svn
    cd ~/svn
    svn checkout --username UserName https://ml01.zrz.tu-berlin.de/svn/ida/public/bbci bbci
    svn checkout --username UserName https://ml01.zrz.tu-berlin.de/svn/ida/public/bbci_tex bbci_tex
    svn checkout --username UserName https://ml01.zrz.tu-berlin.de/svn/ida/public/texmf texmf
    cd ~
    ln -s svn/texmf .

If you plan to work with Stimulus Presentation or Feedbacks, you need
also to install Pyff.

    cd ~/svn
    git pull git://github.com/venthur/pyff

or

    cd ~/svn
    svn checkout https://svn.github.com/venthur/pyff

### Windows

missing

Starting the Toolbox
--------------------

To start the toolbox in Matlab do:

    cd('~/svn/ida/public/bbci/toolbox/startup');
    startup_bbci;

Furthermore, you should specify, where the EEG files are located. The
convention for the toolbox is that there is one data folder (on the
cluster it is `/home/bbci/data/`) which has the subfolders
`bbciRaw` and `bbciMat`. When relative file name
are used, the functions `eegfile_loadBV` and
`eegfile_loadMatlab` would look in those folders. 
 For a complete setup you should add something like the following to
your local `startup.m`:

    global DATA_DIR BBCI_PRINTER
    DATA_DIR='/home/bbci/data/';
    BBCI_PRINTER= 1;
    cd('~/svn/ida/public/bbci/toolbox/startup');
    startup_bbci;
    set_general_port_fields('localhost');
    setup_bbci_online;

