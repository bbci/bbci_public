
Git
===

We're using [git][git] as the version control system for our toolbox. The
repository URL is: https://repo.ml.tu-berlin.de/git/bbci/public.

[git]: http://git-scm.com


Cloning the Repository
----------------------

    git clone https://repo.ml.tu-berlin.de/git/bbci/public


Sparing to type user name and password all the time
---------------------------------------------------

    git config credential.https://repo.ml.tu-berlin.de/git/bbci/public.username BastianVenthur
    git config credential.helper 'cache'

The first line tells git to save your user name *BastianVenthur* permanently
for this repository, so it doesn't need to ask you again and again. The second
line tells git to cache your password for a while (default 15 min).


Git Bash Prompt
---------------

When working on the command line, it is very useful to see in which branch you
currently are. This trick will change your bash prompt, so it will show the
branch you're currently in whenever you are in a git repository.

The trick is the command `__git_ps1` (i.e. `$(__git_ps1)`), put it somewhere in
your `PS1` definition in your `.bashrc`.

**Before:**

    PS1='\u@\h:\W\$ '

**After:**

    PS1='\u@\h:\W$(__git_ps1)\$ '

**Note:** Your PS1 variable  will probably look different when you have a
colored prompt! The important bit it to insert the `$(__git_ps1)` somewhere
near the end of the string.


Getting Help
------------

There is *lots* of useful documentation an help available online:

* Very good reference at [gitref.org](http://gitref.org)
* Documentation on git's homepage [git-scm.com](http://git-scm.com)
* The canonical help git help command (e.g. git help commit)

