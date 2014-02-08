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

```Shell
  mkdir ~/git
  cd ~/git
  git clone http://repo.ml.tu-berlin.de/git/bbci/public bbci_public
```

If you plan to work with our Open Source Framework Pyff for Stimulus Presentation or Feedbacks, you need to get the Pyff repository separately:

```Shell
  git clone git://github.com/venthur/pyff
```


### Mac OS

missing


### Windows

missing


## Starting the Toolbox   <a id="StartUp"></a>

```Matlab
  >> cd('~/git/bbci_public');
  >> startup_public_bbci
```

**TODO:** Add information about optional arguments to the startup function.
