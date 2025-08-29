Guide to ``ctc_data`` Dictionary
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

In the ``basecaller.py`` code, the output of the basecaller is referred
to as ``results``. If an aligner is provided, ``results`` will be
aligned to the reference. ``results`` is an iterator that contains all
``read`` objects and the corresponding ``ctc_data``. The ``ctc_data`` is
a dictionary, which is a structured collection of data used in the
analysis of sequencing reads, particularly in the context of DNA/RNA
sequencing. Below, we outline the key components of the ``ctc_data``
dictionary, their data types, and practical examples of how to use them
based on our discussions. Please refer to the ``CTCWriter`` class in the
``io.py`` file for detailed code regarding ``ctc_data``. This class provides
the necessary implementation details on how ``ctc_data`` is structured and
utilized in the analysis of sequencing reads.

Structure of ``ctc_data``
^^^^^^^^^^^^^^^^^^^^^^^^^

1. **stride**: ``<class 'int'>``

   -  **Description**: Represents the stride value used in the analysis,
      which likely indicates the step size for moving along the sequence
      during processing.

   -  **Example**:

      .. code:: python

         stride = ctc_data['stride']
         print(f"Stride: {stride}")

   -  **Example Value**: ``6``

      -  This means the analysis processes the sequence in steps of 6
         bases.

2. **moves**: ``<class 'numpy.ndarray'>``

   -  **Description**: An array representing the state transitions in a
      model used for sequence analysis. The values (0s and 1s) indicate
      whether a particular base is a match, mismatch, insertion, or
      deletion.

   -  **Example**:

      .. code:: python

         import numpy as np

         moves = ctc_data['moves']
         print(f"Moves: {moves[:100]}")  # Truncated for brevity

   -  **Example Values**:

      .. code:: python

         [1, 0, 1, 1, 0, 1, 1, 0, 1, 0, 1, 1, 0, 1, 1, 0, 0, 1, 1, 0, 0, 1, 1, 0, 0, 1, 0, 0, 0, 1, 0, 1, 1, 0, 0, 0, 1, 1, 0, 0, 1, 0, 1, 0, 1, 0, 0, 1, 0, 1, 1, 1, 1, 0, 1, 1, 0, 1, 1, 1, 0, 1, 0, 1, 1, 0, 1, 1, 0, 0, 0, 0, 1, 0, 1, 0, 1, 1, 0, 1, 0, 0, 0, 1, 1, 0, 1, 0, 0, 1, 1, 0, 0, 0, 0, 1, 1, 0, 1, 0]

3. **qstring**: ``<class 'str'>``

   -  **Description**: A string containing the quality scores of the
      bases in the sequence, encoded in ASCII characters. Each character
      represents the Phred quality score of the corresponding base.

   -  **Example**:

      .. code:: python

         qstring = ctc_data['qstring']
         print(f"Quality String: {qstring[:100]}")  # Truncated for brevity

   -  **Example Value**:

      .. code:: python

         )),.-,,-8;>>@AA8@2CDFL@?@@DJEHROJFSFFLOPNILSIJSKKSOHJPMJNSIHLJJSPINFIGEE8RSLOHFLFC@CDSFMIKGHIHLKSEEB

4. **sequence**: ``<class 'str'>``

   -  **Description**: The DNA/RNA sequence represented as a string of
      nucleotide bases (A, T, C, G).

   -  **Example**:

      .. code:: python

         sequence = ctc_data['sequence']
         print(f"Sequence: {sequence[:100]}")  # Truncated for brevity

   -  **Example Value**:

      .. code:: python

         GGTTTCGTTCGGTTTCCACAGTGAGAAATGAAACTCCCTATTCTACTAAGACTTGCACAAGGGAGTTCCCTTGAAACAAGAAAGAGGATTGAAGTTTGGGTAGGAAAAATGTCAAATATTCCAAAATATGTTACTATGGTTGGCTTCCTAGCTGCATTTTCACCTTTATCCCCATACTAATACTTTAAAATAAGAAGCTCTTGTCTAATGTAACTATTATTTGTATTGTCAAAAATTACAGCCACCCAACTCCAGGACTAGAATCCCTTCCATCTCTAGACCTGTCCCAACTTCACTTCAACAGTCTCTAATACAGAGCCACTCTGTGCCACCAGGTCTCCCTAGGCCAACAGCATCATCATCATCTGGGAACTGGTTAGAAATGGAAATTCTCCAACCACAACCCATCCCTAATGCATTGCAAACCTGGCACATAGGGCTTAGCCATCTGAATTTTAAGAAGCCCGCTGGGTGATTCCAAGTTTTATTCTGGAAGGATCTTCGTCTTTGTTGTTCCATTTTTGTGTAACTAGTAGTCTTCTGTTAGCTTTTTCCACTGAACACGGTAGGACTAGTACCCCAGAGGCTTTCTCAGTTCCGTAAATCCTCCCTCCATTCCCCTTGGTGAAACAGTCATCTTTGGCCACCTAATAGTTAAGTTTAATTCTTGTTTTATTTAAGATTAAAATTTTATCGTTCACTTTTTTTTTCCATAGCATGAGCTTCGTAATGACTGTCAGCCATCTGTGTTGGACATTTTGATGGACTGTCCCAATCTCTCTTCTGGAATGAAAGACCCAAAAATCTAGCTGCTTTGGGGATTGCCTCCACTAAAGAGAGCCTTCTCACTGGACTTCACACCCCTTTCAGGGTGGTCCACATCCAATAACTGATTGCCTCACAGGTGTAAACGACTGACCCTCTTCTTACCCAATTTAGGGC

5. **mapping**: ``<class 'mappy.Alignment'>``

   -  **Description**: An object representing the alignment of the
      sequence to a reference genome. It includes various attributes
      like start and end positions on the query and reference, the
      number of matching bases, and the total length of the alignment.

   -  **Example**:

      .. code:: python

         import mappy as mp

         mapping = ctc_data['mapping']
         if mapping:
             print(f"Reference Chromosome: {mapping.ctg}")
             print(f"Query Start: {mapping.q_st}")
             print(f"Query End: {mapping.q_en}")
             print(f"Matching Length: {mapping.mlen}")
             print(f"Alignment Length: {mapping.blen}")

Practical Applications
~~~~~~~~~~~~~~~~~~~~~~

Calculating Mean Quality Score
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

The quality score string (``qstring``) can be converted into a mean
quality score to assess the overall quality of the sequencing read.

.. code:: python

   import numpy as np

   def mean_qscore_from_qstring(qstring):
       """
       Convert qstring into a mean qscore.
       """
       if len(qstring) == 0: return 0.0
       qs = (np.array(list(qstring), 'c').view(np.uint8) - 33)
       mean_err = np.exp(qs * (-np.log(10) / 10.)).mean()
       return -10 * np.log10(max(mean_err, 1e-4))

   mean_qscore = ctc_data.get('mean_qscore', mean_qscore_from_qstring(ctc_data['qstring']))
   sys.stderr.write(str(mean_qscore) + '\n')

Calculating Coverage and Accuracy
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Coverage and accuracy are important metrics for evaluating the alignment
of a read to a reference genome.

.. code:: python

   mapping = ctc_data.get('mapping')
   seq = ctc_data['sequence']

   if mapping:
       cov = (mapping.q_en - mapping.q_st) / len(seq)
       acc = mapping.mlen / mapping.blen
       print(f"Coverage: {cov}")
       print(f"Accuracy: {acc}")

Output Formatting
^^^^^^^^^^^^^^^^^

For debugging or logging purposes, it is often useful to format the
output in a clear and readable manner.

.. code:: python

   def write_with_dashes(content):
       sys.stderr.write('-' * 90 + '\n')
       sys.stderr.write(content + '\n')
       sys.stderr.write('-' * 90 + '\n')

   write_with_dashes(str(ctc_data['stride']))
   write_with_dashes(str(list(ctc_data['moves'][:100])))  # Truncated for brevity
   write_with_dashes(ctc_data['qstring'][:100])  # Truncated for brevity
   write_with_dashes(ctc_data['sequence'][:100])  # Truncated for brevity
   write_with_dashes(str(mean_qscore))

Conclusion
~~~~~~~~~~

The ``ctc_data`` dictionary is a comprehensive structure that
encapsulates critical information about sequencing reads and their
alignments. Understanding and utilizing the components of this
dictionary can significantly aid in the analysis and interpretation of
sequencing data.
