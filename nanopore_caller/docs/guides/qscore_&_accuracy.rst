Tutorial on Q-score and Accuracy Arguments
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

This tutorial will guide you through understanding and computing
Q-scores and accuracy using the Bonito package, which is used for
basecalling in nanopore sequencing. We’ll explore how the Bonito
basecaller computes these metrics and their significance in assessing
the quality of DNA sequencing data.

Understanding Q-score and Accuracy
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

-  **Q-score**: A quality score (Q-score) represents the confidence in
   the accuracy of each base call in DNA sequencing. Higher Q-scores
   indicate higher confidence. The Q-score is typically calculated using
   the ``mean_qscore_from_qstring`` function, which converts a quality
   string into a mean Q-score.
-  **Accuracy**: Accuracy in sequence alignment measures the proportion
   of correctly aligned bases (matches) relative to the total number of
   aligned bases (including matches, mismatches, insertions, and
   deletions). The ``accuracy`` function calculates this metric by
   aligning the basecalled sequence to a reference sequence.

Step-by-Step Tutorial
~~~~~~~~~~~~~~~~~~~~~

1. Basecalling Reads
^^^^^^^^^^^^^^^^^^^^

Basecalling is the process of converting raw signal data from sequencing
into nucleotide sequences (A, T, C, G). The ``basecall`` function in
Bonito performs this task. It processes reads in chunks, computes scores
for each chunk using the ``compute_scores`` function, and stitches the
results together using the ``stitch_results`` function to produce the
final basecalled sequences.

The ``stitch_results`` function combines the chunk results into a
complete sequence with the given overlap, ensuring continuity and
coherence in the final output.

2. Compute Scores
^^^^^^^^^^^^^^^^^

The ``compute_scores`` function computes the scores for the model for
each batch, including the sequence, quality string (qstring), and moves.
This function is essential for evaluating the confidence in each base call
made by the model.

To use this function: - Call ``compute_scores`` with the model and batch
of reads. - Extract the sequence and qstring from the results.

3. Format Results
^^^^^^^^^^^^^^^^^

The ``fmt`` function formats the results obtained from basecalling. It
adjusts the sequence and quality string, reversing them if the data is
RNA, and prepares them for further analysis.

To use this function: - Pass the stride and attributes (such as moves,
qstring, sequence) obtained from basecalling to ``fmt``. - The function
will return a dictionary with formatted results.

4. Calculate Mean Q-score
^^^^^^^^^^^^^^^^^^^^^^^^^

The mean Q-score provides a measure of the average confidence across all
base calls in a sequence. Use the ``mean_qscore_from_qstring`` function
to calculate the mean Q-score from the quality string.

To calculate the mean Q-score: - Pass the qstring obtained from
``compute_scores`` to ``mean_qscore_from_qstring``. - Print or store the
resulting mean Q-score.

5. Calculate Accuracy
^^^^^^^^^^^^^^^^^^^^^

Accuracy is calculated by comparing the basecalled sequence to a
reference sequence. The ``accuracy`` function performs this calculation
by aligning the sequences and computing the proportion of correctly
aligned bases using the Smith-Waterman algorithm.

To calculate accuracy: - Define a reference sequence. - Call the
``accuracy`` function with the reference and basecalled sequences. -
Print or store the resulting accuracy score.

Difference Between Mean Q-score and Accuracy
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Understanding the distinction between Mean Q-score and Accuracy is
crucial for evaluating sequencing data quality:

Mean Q-score:
^^^^^^^^^^^^^

-  **Purpose**: The Mean Q-score provides a measure of the confidence in
   each base call across an entire sequence. It reflects the probability
   that a given base call is correct.
-  **Calculation**: Derived from the Phred scale, where Q = -10 \*
   log10(P), with P being the probability of an incorrect base call. For
   example, a Q-score of 30 indicates a 1 in 1000 chance of an incorrect
   base call (99.9% accuracy).
-  **Usage**: Used primarily to assess the quality of individual base
   calls produced by the sequencing instrument. Higher Q-scores indicate
   better base call quality.

Accuracy:
^^^^^^^^^

-  **Purpose**: Accuracy measures the correctness of the sequence
   alignment by comparing the basecalled sequence to a reference
   sequence. It accounts for all aligned bases, including matches,
   mismatches, insertions, and deletions.
-  **Calculation**: Calculated as the proportion of correctly aligned
   bases (matches) out of the total number of aligned bases. For
   instance, if there are 95 matches out of 100 aligned bases, the
   accuracy is 95%.
-  **Usage**: Used to evaluate the overall performance of the alignment
   process and the fidelity of the basecalled sequence compared to a
   known reference.

Key Differences:
~~~~~~~~~~~~~~~~

1. **Metric Type**:

   -  **Q-score**: Represents the quality/confidence of individual base
      calls.
   -  **Accuracy**: Represents the correctness of the entire sequence
      alignment.

2. **Calculation Basis**:

   -  **Q-score**: Derived from the error probability of base calls.
   -  **Accuracy**: Derived from the comparison between the aligned
      sequences.

3. **Purpose**:

   -  **Q-score**: Helps determine the quality of sequence data at the
      base level.
   -  **Accuracy**: Helps evaluate the performance of alignment
      algorithms and the correctness of sequence comparisons.

4. **Representation**:

   -  **Q-score**: Typically expressed in logarithmic scale (Phred
      score).
   -  **Accuracy**: Expressed as a percentage or fraction.

Conclusion
~~~~~~~~~~

In this tutorial, we explored how to compute Q-scores and alignment
accuracy using the Bonito package. Q-scores provide a measure of the
confidence in base calls, while accuracy indicates how well the
basecalled sequences align with a reference. Together, these metrics
help assess the quality and reliability of DNA sequencing data, ensuring
that the basecalling process produces high-quality, accurate results.
Understanding both metrics is essential for effective sequencing data
analysis and interpretation.
