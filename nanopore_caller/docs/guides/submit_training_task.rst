Submitting a Training Task on GPU in SCC
========================================

This document explains the bash script for submitting a task on GPU in the Shared Computing Cluster (SCC). The script includes various options and settings necessary for job submission.

Bash Script Explanation
------------------------

Script Header
~~~~~~~~~~~~~

.. code:: bash

   #!/bin/bash -l

This line specifies the shell to be used (``/bin/bash``) with the ``-l`` option to make the shell act as a login shell.

SCC Project and Job Name
~~~~~~~~~~~~~~~~~~~~~~~~~

.. code:: bash

   #$ -P leshlab       
   #$ -N bonito_training    

- ``-P leshlab``: Specifies the SCC project name.
- ``-N bonito_training``: Sets the name of the job.

Time Limit
~~~~~~~~~~

.. code:: bash

   #$ -l h_rt=12:00:00

Sets a hard time limit of 12 hours for the job. The job will be aborted if it runs longer than this time.

GPU Request
~~~~~~~~~~~

.. code:: bash

   #$ -l gpus=1

Requests 1 GPU for the job.

GPU Type
~~~~~~~~

.. code:: bash

   #$ -l gpu_type=L40S

Specifies the type of GPU to be used. In this case, it's ``L40S``.

Email Notifications
~~~~~~~~~~~~~~~~~~~

.. code:: bash

   #$ -m ea

Sends an email when the job finishes or if it is aborted.

Output and Error Files
~~~~~~~~~~~~~~~~~~~~~~

.. code:: bash

   #$ -j y

Combines output and error files into a single file.

Job Information
~~~~~~~~~~~~~~~

.. code:: bash

   echo "=========================================================="
   echo "Start date : $(date)"
   echo "Job name : $JOB_NAME"
   echo "Job ID : $JOB_ID  $SGE_TASK_ID"
   echo "=========================================================="

Prints job-related information, such as the start date, job name, and job ID.

Loading Modules
~~~~~~~~~~~~~~~

.. code:: bash

   module load cuda
   module load miniconda

Loads the necessary modules, CUDA and Miniconda, required for the job.

Activating Conda Environment
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. code:: bash

   conda activate bonito_env

Activates the Conda environment named ``bonito_env``.

Python Information
~~~~~~~~~~~~~~~~~~

.. code:: bash

   echo "Python executable: $(which python)"
   echo "Python version: $(python --version)"

Prints the path to the Python executable and the Python version being used.

Bonito Training Command
~~~~~~~~~~~~~~~~~~~~~~~

.. code:: bash

   bonito train -f /path/to/training/models --lr 2e-4 --epochs 5

Runs the Bonito training command with specified parameters:
- ``-f /path/to/training/models``: Specifies the training models directory.
- ``--lr 2e-4``: Sets the learning rate.
- ``--epochs 5``: Sets the number of epochs.

Creating a ``.sh`` File
------------------------

To create a shell script (``.sh`` file) from the above script:

1. Open a text editor (e.g., ``nano``, ``vim``, ``gedit``).
2. Copy and paste the entire script into the editor.
3. Save the file with a ``.sh`` extension, for example, ``submit_gpu_task.sh``.
4. Make the script executable by running the following command in the terminal:

   .. code:: bash

      chmod +x submit_gpu_task.sh

5. Submit the script to the SCC using the command:

   .. code:: bash

      qsub submit_gpu_task.sh

This concludes the explanation and instructions for creating and submitting the bash script for a GPU task on SCC.