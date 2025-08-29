POD5: Efficient Storage for Nanopore Signal Data
================================================

Overview
--------

POD5 is a new file format designed for storing nanopore signal data
efficiently. It addresses the performance and reliability issues faced
with the previous Fast5 format. The format consists of tables in Apache
Arrow’s Feather 2.0 storage format, concatenated together with
additional information to indicate the location of the tables within the
file. This document provides an overview of key concepts, the motivation
behind POD5, its structure, and how to get started with it.

Key Concepts
------------

Signal
~~~~~~

-  Measurement of electrical current across a nanopore as a time-ordered
   series of samples.
-  Broken down into reads, representing the signal for a single strand
   of DNA or RNA.

Base Calling
~~~~~~~~~~~~

-  The process of converting signal data into DNA or RNA sequences.
-  Typically performed by machine learning models, such as recurrent
   neural networks.
-  Requires extensive signal data for training models.

Why Store Signal Data?
----------------------

-  **Post-Processing**: Allows for analysis on HPC systems.
-  **Multiple Base Calls**: Enables re-base calling with different
   parameters or future base callers.
-  **Training Models**: Necessary for developing and improving base
   calling models.

Fast5: The Previous Format
--------------------------

-  Based on HDF5, an industry-standard in scientific computing.
-  Benefits:

   -  Extensive ecosystem (HDFView, H5Py, NumPy).
   -  Capable of storing diverse data types in one file.

-  Drawbacks:

   -  Performance issues due to single-threaded read/write operations.
   -  Difficulties in recovering partially written files.
   -  Complexity in achieving optimal performance.

POD5: The New Format
--------------------

-  Designed for better performance and reliability.
-  **Performance**:

   -  Efficient data writing even with unknown read lengths.
   -  Faster reading for base callers and training systems.

-  **Reliability**:

   -  Improved data recovery from partially written files.

Structure of POD5
-----------------

-  **Apache Arrow Tables**: Three main tables bundled in a simple
   container format.

   -  **Reads**: Contains metadata for the reads.
   -  **Run Information**: Stores experiment-level information.
   -  **Signal**: Contains the raw signal data for reads.

Why Apache Arrow?
~~~~~~~~~~~~~~~~~

-  **Performance**: Organized for efficient analytic operations on
   modern hardware.
-  **Zero-Copy Reads**: Fast data access.
-  **Columnar Layout**: Efficient data operations.
-  **Ecosystem**: Compatibility with pandas, MATLAB, etc.
-  **Data Recovery**: Easier recovery of partially written files.

Container Format
~~~~~~~~~~~~~~~~

-  **Simplicity**: Retain the simplicity of FAST5 by having everything
   contained in a single file.
-  **Performance Gains**: Easy reading and uploading of files.

Getting Started with POD5
-------------------------

-  **GitHub Repository**: `POD5 GitHub <https://github.com/your-repo>`__

   -  Specifications in the ``docs`` directory.
   -  Reference implementation in C++ with a C interface.
   -  Python library and tools with wheels for common platforms.

-  **Converter Tool**: Available online at
   `pod5.94tech.com <https://pod5.94tech.com>`__.

-  **Installation**:

   .. code:: bash

      pip install pod5

Future and Updates
------------------

-  No planned changes to the file format, ensuring stability for users.

Conclusion
----------

POD5 offers a robust, efficient, and reliable way to store and handle
nanopore signal data, addressing the limitations of Fast5 and supporting
advanced data processing needs.
