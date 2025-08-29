GitHub Guide for Linux Terminal
===============================

This guide provides a concise step-by-step process to connect to a GitHub repository, create a branch, and manage pull and push operations in a Linux terminal.

Prerequisites
-------------

Ensure Git is installed:

.. code-block:: bash

  sudo apt update
  sudo apt install git

Steps
-----

1. Configure Git

   .. code-block:: bash

     git config --global user.name "Your Name"
     git config --global user.email "your.email@example.com"

2. Clone the Repository

   .. code-block:: bash

     git clone https://github.com/your-username/your-repo.git
     cd your-repo

3. Create a New Branch

   .. code-block:: bash

     git checkout -b new-branch-name

4. Make Changes

   Create a New Folder and Add a File

   .. code-block:: bash

     mkdir new-folder
     echo "Your content here" > new-folder/new-file.txt

5. Add Changes

   .. code-block:: bash

     git add .

6. Commit Changes

   .. code-block:: bash

     git commit -m "Describe your changes"

7. Push Branch to GitHub

   .. code-block:: bash

     git push origin new-branch-name

8. Pull Latest Changes

   .. code-block:: bash

     git pull origin main

Notes
-----

- Replace ``your-username``, ``your-repo``, and ``new-branch-name`` with your actual GitHub username, repository name, and desired branch name.
- Ensure you have the necessary permissions to push to the repository.
- When you clone a repository from GitHub, by default, you are cloning the default branch, which is often the main or master branch. If you made a branch before and the branch you created contains other files and is different from the default branch, you will need to switch to that branch after cloning the repository. For this purpose, you need to use ``git checkout your-branch-name``.

Steps on how to connect to your GitHub account
----------------------------------------------

GitHub no longer supports password authentication for Git operations over HTTPS. Instead, you should use a Personal Access Token (PAT) for HTTPS or SSH keys for authentication. By following these steps, you can set up secure authentication methods for cloning, pushing, and pulling from your GitHub repositories. Here’s how you can set up both methods:

Method 1: Using a Personal Access Token (PAT)
---------------------------------------------

1. Generate a Personal Access Token:

   - Go to your GitHub account.
   - Navigate to ``Settings`` > ``Developer settings`` > ``Personal access tokens``.
   - Click ``Generate new token``.
   - Select the scopes or permissions you need.
   - Click ``Generate token`` and copy the token.

2. Use the Token for Cloning:

   When prompted for a username and password while cloning, use your GitHub username and the generated token as the password:

   .. code-block:: bash

     git clone https://github.com/your-username/your-repository.git

   When asked for your username, enter your GitHub username. When asked for your password, paste the personal access token.

Method 2: Using SSH Keys
------------------------

1. Generate an SSH Key:

   - Open a terminal and run:

     .. code-block:: bash

       ssh-keygen -t ed25519 -C "your_email@example.com"

   - Follow the prompts to save the key to the default location (``~/.ssh/id_ed25519``) and set a passphrase if desired.

2. Add the SSH Key to the SSH Agent:

   - Start the SSH agent in the background:

     .. code-block:: bash

       eval "$(ssh-agent -s)"

   - Add your SSH private key to the SSH agent:

     .. code-block:: bash

       ssh-add ~/.ssh/id_ed25519

3. Add the SSH Key to Your GitHub Account:

   - Copy the SSH key to your clipboard:

     .. code-block:: bash

       cat ~/.ssh/id_ed25519.pub

   - Go to your GitHub account.
   - Navigate to ``Settings`` > ``SSH and GPG keys``.
   - Click ``New SSH key``, give it a title, and paste the key.
   - Click ``Add SSH key``.

4. Clone the Repository Using SSH:

   - Use the SSH URL to clone the repository:

     .. code-block:: bash

       git clone git@github.com:your-username/your-repository.git

How to update the main branch of your local repository to match the remote repository
-------------------------------------------------------------------------------------

Follow these steps:

1. Open your terminal or command prompt.

2. Navigate to your local repository. Use the ``cd`` command to go to the directory where your repository is located. For example:

   .. code-block:: bash

     cd path/to/your/repository

3. Fetch the latest changes from the remote repository. This command updates your local copy of the remote branches:

   .. code-block:: bash

     git fetch origin

4. Check out your local main branch. Make sure you are on your local main branch:

   .. code-block:: bash

     git checkout main

5. Merge the changes from the remote main branch into your local main branch. This command updates your local main branch with the latest changes from the remote main branch:

   .. code-block:: bash

     git merge origin/main

Alternatively, you can use the ``pull`` command, which is a shorthand for ``fetch`` followed by ``merge``:

   .. code-block:: bash

     git pull origin main

How to prevent loss of work and to recover your branch updates
--------------------------------------------------------------

By following these steps, you can safeguard your updates and ensure you can recover them if someone force-resets the main branch.

Step 1: Backup Your Work
^^^^^^^^^^^^^^^^^^^^^^^^

Before performing any operations that might affect your branch, create a backup branch:

.. code-block:: bash

  git checkout main
  git checkout -b backup-main
  git push origin backup-main

Step 2: Recover Lost Commits
^^^^^^^^^^^^^^^^^^^^^^^^^^^^

If the main branch has been force-reset, you can still recover your commits if you have a local copy of the repository or if you have a backup branch.

Recover from Local Repository
+++++++++++++++++++++++++++++

If your commits are still present in your local repository (in the reflog):

1. Check Reflog:

   .. code-block:: bash

     git reflog

   Find the commit hash of the last commit before the reset.

2. Reset to the Last Commit:

   .. code-block:: bash

     git reset --hard <commit-hash>

3. Force-Push to Restore:

   .. code-block:: bash

     git push --force origin main

Recover from a Backup Branch
++++++++++++++++++++++++++++

If you have a backup branch:

1. Check Out the Backup Branch:

   .. code-block:: bash

     git checkout backup-main

2. Reset Main to Backup Branch:

   .. code-block:: bash

     git checkout main
     git reset --hard backup-main

3. Force-Push the Changes:

   .. code-block:: bash

     git push --force origin main

Step 3: Communicate with Your Team
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Ensure all team members are aware of the force-push operation to prevent confusion and potential conflicts.
