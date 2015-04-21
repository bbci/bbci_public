# Contributing Code to the Toolbox


## tl;dr

The very short summary (tl;dr = too long; didn't read) describing how to
contribute code to the toolbox is:

* Fork the toolbox repository
* Clone your fork
* Create a feature branch to add a feature or fix a bug
* Push the feature branch to your fork
* Create a pull request

A detailed explanation follows below.


## General Workflow

Instead of committing directly to the project's repository, you *create your own
private fork* of the project. Forking a repository allows you to freely
experiment with changes without affecting the original project.

In order to fix a bug or creating a new feature, it is best to create a new
*feature branch* for each bugfix or new feature. Those branches can be pushed to
your fork and merged back into the original toolbox repository independently.

When you're happy with your changes, you can propose to get the changes merged
back into the original project by creating a *pull request* for the feature
branch.


## Forking the Project

We assume you already have a GitHub account. If you don't have a GitHub account,
please [create an account][join_github] now, it's free.

1. Goto the [toolbox repository page on github][bbci_public]
2. In the top-right corner of the page, click **Fork**.

That's it! Now you have a *fork* of the original project repository. You are
free to add files, modify files, or even delete the repository without affecting
the original project.


## Keep Your Fork Synced

Right now, you have a fork of the toolbox repository, but you don't have any
files of that repository on your computer. Let's create a *clone* of your fork
on your computer.

1. On GitHub, navigate to *your fork* of the toolbox repository
   (https://github.com/YOUR_USERNAME/bbci_public).
2. In the right sidebar you'll find the *clone URL* of your fork. Copy that URL.
3. Open a terminal.
4. Type `git clone`, and paste the URL you copied in step 2 and press Enter:

   ```
   git clone git@github.com:YOUR-USERNAME/bbci_toolbox.git
   Cloning into 'bbci_public'...
   remote: Counting objects: 5262, done.
   remote: Total 5262 (delta 0), reused 0 (delta 0), pack-reused 5262
   Receiving objects: 100% (5262/5262), 3.28 MiB | 700.00 KiB/s, done.
   Resolving deltas: 100% (3646/3646), done.
   Checking connectivity... done.
   ```

   Now, you have a local copy of your fork of the toolbox repository!

   In the next steps we configure git so it allows you to pull changes from the
   original, or *upstream*, repository into the local clone of your fork.

5. On GitHub, navigate to the [original BBCI toolbox page][bbci_public]
6. In the right sidebar, copy that *clone URL* of the repository.
7. Open a terminal and change into the directory of your local clone.
8. Type `git remote -v` and press Enter. You'll see the current configured
   repository for your fork:

   ```
   git remove -v
   origin    git@github.com:YOUR_USERNAME/bbci_public.git (fetch)
   origin    git@github.com:YOUR_USERNAME/bbci_public.git (push)
   ```

9. Type `git remote add upstream`, and then paste the URL you copied in Step 7
   and press Enter:

   ```
   git remote add upstream git@github.com/bbci/bbci_public.git
   ```

10. To verify the new upstream repository, type again `git remote -v`. You
    should see the URL for your fork as `origin` and the original repository as
    `upstream`.

    ```
    git remote -v
    origin    git@github.com:YOUR_USERNAME/bbci_public.git (fetch)
    origin    git@github.com:YOUR_USERNAME/bbci_public.git (push)
    upstream  git@github.com:bbci/bbci_public.git (fetch)
    upstream  git@github.com:bbci/bbci_public.git (push)
    ```


## Working on a Feature Branch

Let's assume you want to fix a bug or write a new feature. Instead of working
directly on the `master` branch of the repository, it is often preferable to
make changes in a separate branch and merge that branch back into `master` once
everything is ready. Let's create a new branch for our feature, called
`myfeature`:

```
git checkout -b myfeature
```

You've now created a branch `myfeature` and git automatically switched to that
branch for you. In this branch, you can now make changes and commits as usually:

```
# edit files foo and bar
git add foo bar
git commit
# create file baz
git add baz
git commit
# ...
```

You can also switch back and forth between branches:

```
git checkout master
# you are now in the master branch

git checkout myfeature
# you're back in the feature branch
```

## Creating a Pull Request

So far you have added a new feature or fixed a bug in a *feature branch* of your
local clone of your fork of the original toolbox repository. You now want these
changed to be merged into the original repository.

1. Push your feature branch into *your* GitHub repository:

   ```
   git checkout myfeature
   git push origin myfeature
   ```
2. Navigate to your GitHub repository and switch to the `myfeature` branch by
   selecting it from the dropdown box above the file listing.
3. Click **Pull Request** above the file listing, fill out the form, and
   finish by clicking **Create Pull Request**

You've now created a pull request. That pull request appears in the original,
upstream repository where the maintainers can comment on your pull request,
request some more changes, reject or accept your pull request.


[bbci_public]: https://github.com/bbci/bbci_public
[join_github]: https://github.com/join


