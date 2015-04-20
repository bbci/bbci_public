## General Workflow

Instead of committing directly to the project's repository, you *create your own
private fork* of the project. Forking a repository allows you to freely
experiment with changes without affecting the original project.

[BRANCH]

When you're happy with your changes, you can propose to get the changes merged
back into the original project by creating a *pull request*.


## Forking the Project

We assume you already have a GitHub account. If you don't have a GitHub account,
please [create an account][join_github] now, it's free.

  1. Goto the [toolbox repository page on github][bbci_public]
  2. In the top-right corner of the page, click **Fork**.

That's it! Now you have a *fork* of the original project repository. You are
free to add files, modify files, or even delete the repository without affecting
the original project.

  [bbci_public]: https://github.com/bbci/bbci_public
  [join_github]: https://github.com/join


## Keep Your Fork Synced

Right now, you have a fork of the toolbox repository, but you don't have any
files of that repository on your computer. Let's create a *clone* of your fork
on your computer.

  1. On GitHub, navigate to *your fork* of the toolbox repository
     (https://github.com/YOUR_USERNAME/bbci_public).
  2. In the right sidebar you'll find the *clone URL* of your fork. Copy that
     URL.
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

  1. On GitHub, navigate to the [original BBCI toolbox page][bbci_toolbox]
  2. In the right sidebar, copy that *clone URL* of the repository.
  3. Open a terminal and change into the directory of your local clone.
  4. Type `git remote -v` and press Enter. You'll see the current configured
     repositry for your fork:

    ```
    git remove -v
    origin	git@github.com:YOUR_USERNAME/bbci_public.git (fetch)
    origin	git@github.com:YOUR_USERNAME/bbci_public.git (push)
    ```

  5. Type `git remote add upstream`, and then paste the URL you copied in Step 2
     and press Enter:

    ```
    git remote add upstream git@github.com/bbci/bbci_public.git
    ```

  6. To verify the new upstream repository, type again `git remote -v`. You
     should see the URL for your fork as `origin` and the original repository as
     `upstream`.

    ```
    git remote -v
    origin    git@github.com:YOUR_USERNAME/bbci_public.git (fetch)
    origin    git@github.com:YOUR_USERNAME/bbci_public.git (push)
    upstream  git@github.com:bbci/bbci_public.git (fetch)
    upstream  git@github.com:bbci/bbci_public.git (push)
    ```


## Working on a feature branch

Let's assume you want to fix a bug or write a new feature. Instead of working
directly on the `master` branch of the repository, it is often preferable to
make changes in a separate branch and merge that branch back into `master` once
everything is ready. Let's create a new branch for our feature, called
`myfeature`:

```
git checkout -b myfeature
```

## Updating the code

```
git pull
```

