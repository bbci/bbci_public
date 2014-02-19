---

# Documentation: Setting up and Starting the Toolbox

---

***under construction***

---

* [Checking out the GIT repository of the BBCI Toolbox](#CheckOut)
* [Starting the toolbox in Matlab](#StartUp)

---

## Checking out the GIT repository of the BBCI Toolbox   <a id="CheckOut"></a>

The GIT repository is available under the following link:

> http://repo.ml.tu-berlin.de/git/bbci/public


### Linux

```Bash
  mkdir ~/git
  cd ~/git
  git clone http://repo.ml.tu-berlin.de/git/bbci/public bbci_public
```

If you plan to work with our Open Source Framework Pyff for Stimulus Presentation or Feedbacks, you need to get the Pyff repository separately:

```Bash
  git clone git://github.com/venthur/pyff
```


### Mac OS

missing


### Windows

Git for Windows can be downloaded from here:

> http://msysgit.github.io/

Installing Git for Windows will add git-related options to the context menu of the Windows Explorer (i.e. you will see these options when you right-click on a folder). 

After installing Git for Windows, open the folder in which you would like to store the BBCI Toolbox. In this folder, right-click to open the context menu and choose the option 'Git Bash'. A terminal window (bash) will open. In the terminal window type

```Bash
  git clone http://repo.ml.tu-berlin.de/git/bbci/public
```

Alternatively, you can use the GUI provided by Git for Windows to clone the repository. The GUI appears when you choose Git GUI from the context menu.


## Starting the Toolbox   <a id="StartUp"></a>

```Matlab
  >> cd('~/git/bbci_public');
  >> startup_public_bbci
```

**TODO:** Add information about optional arguments to the startup function.
