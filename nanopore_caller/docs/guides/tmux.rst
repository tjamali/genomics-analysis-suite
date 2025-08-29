tmux Tutorial
=============

``tmux`` is an invaluable tool for anyone who frequently works with
terminal applications. It allows you to create, manage, and navigate
multiple terminal sessions within a single window, enhancing
productivity and efficiency. By detaching and reattaching sessions, you
can keep long-running processes active even when you disconnect from
your terminal, ensuring that tasks like code compilation, training
machine learning models, or running server processes continue
uninterrupted. Additionally, ``tmux`` offers features like window
splitting and session management, making it easier to organize and
monitor various tasks simultaneously. This makes ``tmux`` essential for
developers, system administrators, and anyone who relies heavily on
command-line operations.

Installation
------------

On Ubuntu/Debian
~~~~~~~~~~~~~~~~

.. code:: sh

   sudo apt-get update
   sudo apt-get install tmux

On macOS
~~~~~~~~

.. code:: sh

   brew install tmux

Essential Commands
------------------

Start a New tmux Session
~~~~~~~~~~~~~~~~~~~~~~~~

To start a new tmux session, simply type:

.. code:: sh

   tmux new -s my_session_name

Detach from the tmux Session
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Once your training script is running, you can detach from the tmux
session by pressing ``Ctrl + b`` followed by ``d``. This will return you
to the regular terminal prompt while leaving the tmux session and your
training process running in the background.

Reattach to the tmux Session (Optional)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

If you want to check on the progress of your training or view any
output, you can reattach to the tmux session later by typing:

.. code:: sh

   tmux attach -t my_session_name

Useful Commands
---------------

-  **List Sessions**: ``tmux ls``
-  **Kill a Session**: ``tmux kill-session -t my_session_name``
