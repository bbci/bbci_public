
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

Getting Help
------------

There is *lots* of useful documentation an help available online:

* Very good reference at [gitref.org](http://gitref.org)
* Documentation on git's homepage [git-scm.com](http://git-scm.com)
* The canonical help git help command (e.g. git help commit)

