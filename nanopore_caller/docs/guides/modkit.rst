
**Modkit Tutorial**
-------------------

This tutorial will guide you through using **Modkit** to detect base
modifications and save the results in a BED file. We’ll first explore
the various tags available in the ``modkit pileup`` command, followed by
a detailed explanation of the columns in the resulting BED file.

1. Understanding ``modkit pileup`` Tagg
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Modkit offers a range of tags to fine-tune your analysis of base
modifications. Here’s a breakdown of the tags you can use:

1.1. ``log-filepath``
^^^^^^^^^^^^^^^^^^^^^^^^^

-  **Explanation**: Specifies a file for debug logs. If not set, debug
   logs are ignored.
-  **Details**: Used for debugging purposes to capture detailed logs
   during execution. Helpful for troubleshooting.

1.2. ``region``
^^^^^^^^^^^^^^^^^^^

-  **Explanation**: Limits pileup to a specified region of the BAM file.
-  **Details**: The format is ``<chrom_name>:<start>-<end>`` or just
   ``<chrom_name>``. This option is useful for focusing on a specific
   genomic region.

1.3. ``threads``
^^^^^^^^^^^^^^^^^^^^

-  **Explanation**: Sets the number of threads for concurrent
   processing.
-  **Details**: Default is 4 threads. This is important for performance
   optimization on multi-core systems.

1.4. ``num-reads``
^^^^^^^^^^^^^^^^^^^^^^

-  **Explanation**: Samples a specific number of reads when estimating
   filtering thresholds.
-  **Details**: Defaults to 10,042 reads. Reducing or increasing this
   number can affect the accuracy of threshold estimation and processing
   time.

1.5. ``no-filtering``
^^^^^^^^^^^^^^^^^^^^^^^^^

-  **Explanation**: Disables filtering, including all base modification
   calls in the output.
-  **Details**: Useful when you want raw data without any filtering
   applied. Typically used for detailed analysis or when custom
   filtering will be applied later.

1.6. ``filter-threshold``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

-  **Explanation**: Sets a filter threshold globally or per base.
-  **Details**: This option allows you to set filtering thresholds
   either globally (for all bases) or specifically for individual bases.
   *Global filter threshold* can be specified with a single decimal
   number. For example, ``--filter-threshold 0.75`` would apply a
   threshold of 0.75 to all bases. *Per-base thresholds* can be
   specified using a format like ``C:0.75``, where ``C`` stands for
   cytosine, and ``0.75`` is the threshold for that base. You can set
   thresholds for multiple bases by repeating the option: e.g.,
   ``--filter-threshold C:0.75 --filter-threshold A:0.70``. If you want
   to specify a default threshold for all bases while setting a specific
   threshold for a particular base, you can do something like
   ``--filter-threshold A:0.70 --filter-threshold 0.9``. This sets a
   threshold of 0.70 for adenine (A) and 0.9 for all other bases.

1.7. ``mod-thresholds``
^^^^^^^^^^^^^^^^^^^^^^^^^^^

-  **Explanation**: Sets a pass threshold for specific modifications.
-  **Details**: Useful for fine-tuning analysis for specific
   modifications like 5hmC. This option lets you specify thresholds for
   specific base modifications, independent of the thresholds set for
   the primary sequence bases. For example, to set a threshold of 0.8
   for 5hmC (hydroxymethylcytosine), you would use
   ``--mod-threshold h:0.8``. The tool will still estimate and apply
   thresholds for the canonical bases unless you also specify them using
   the ``--filter-threshold`` option. This threshold operates
   independently of the primary base’s threshold. The following
   modification codes are defined and can be used with the
   ``--mod-threshold`` tag in Modkit:

   - **Cytosine Modifications**:
      - `m`: Methylcytosine 
      - `h`: Hydroxymethylcytosine
      - `f`: Formylcytosine 
      - `c`: Carboxycytosine 
      - `C`: Any Cytosine 
      - 21839: `FOUR_METHYL_CYTOSINE` 
      
   - **Adenine Modifications**:
      - `a`: Six-Methyladenine 
      - `A`: Any Adenine 
      - 17596: `INOSINE` 

   - **Thymine/Uracil Modifications**:
      - `g`: Hydroxymethyluracil 
      - `e`: Formyluracil 
      - `b`: Carboxyuracil 
      - `T`: Any Thymine 
      - 17802: `PSEUDOURIDINE` 
      - 16450: `DEOXY_URACIL` 

   - **Guanine Modifications**:
      - `o`: Oxo-guanine 
      - `G`: Any Guanine 

1.8. ``sample-region``
^^^^^^^^^^^^^^^^^^^^^^^^^^

-  **Explanation**: Specifies a region for sampling reads for threshold
   estimation.
-  **Details**: Similar to ``--region``, but specifically for sampling
   during threshold estimation.

1.9. ``motif``
^^^^^^^^^^^^^^^^^^

-  **Explanation**: Outputs pileup counts for specific sequence motifs.
-  **Details**: Takes two arguments: the sequence motif and the offset.
   For example, ``--motif CGCG 0`` targets specific bases in motifs.

1.10. ``cpg``
^^^^^^^^^^^^^^^^^

-  **Explanation**: Outputs counts only at CpG motifs.
-  **Details**: A shorthand for ``--motif CG 0``. Requires a reference
   sequence.

1.11. ``ref``
^^^^^^^^^^^^^^^^^

-  **Explanation**: Specifies the reference sequence in FASTA format.
-  **Details**: Required for motif filtering, especially for CpG
   analysis.

1.12. ``preset``
^^^^^^^^^^^^^^^^^^^^

-  **Explanation**: Applies a set of preset options for specific
   applications.
-  **Details**: For example, the ``traditional`` preset applies options
   for 5mC analysis, combining strands, and ignoring specific
   modifications like 5hmC.

1.13. ``combine-strands``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

-  **Explanation**: Combines counts from positive and negative strands
   in motif analysis.
-  **Details**: Useful for symmetrical motifs like CpG, where both
   strands are of interest.

1.14. ``invert-edge-filter``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

-  **Explanation**: Inverts the edge filter to keep only base
   modification calls at the ends of reads.
-  **Details**: Normally, the edge filter removes modifications at the
   ends of reads; this option keeps them.

1.15. ``with-header``
^^^^^^^^^^^^^^^^^^^^^^^^^

-  **Explanation**: Includes a header in the bedMethyl output.
-  **Details**: This can be useful for keeping track of column
   definitions in downstream analysis.

1.16. ``prefix``
^^^^^^^^^^^^^^^^^^^^

-  **Explanation**: Sets a prefix for output file names.
-  **Details**: Without this option, the files are named based on the
   modification code and strand.

1.17. ``partition-tag``
^^^^^^^^^^^^^^^^^^^^^^^^^^^

-  **Explanation**: Partitions output into multiple bedMethyl files
   based on tag-value pairs.
-  **Details**: This allows for more granular analysis by grouping data
   based on tags.

**2. Interpreting the BED File Output**
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Once you’ve run the ``modkit pileup`` command with your desired
settings, the output will be saved in a BED file. Here’s what each
column in the BED file represents:

**Sample BED File Row:**
^^^^^^^^^^^^^^^^^^^^^^^^

::

   chr12   25205243        25205244        a       5       -       25205243        25205244        255,0,0      5       40.00   2       3       0       0       8       0       0

**Column Breakdown:**
^^^^^^^^^^^^^^^^^^^^^

1.  **Chromosome** (``chrom``):

    -  This column indicates the chromosome on which the feature is
       located. In your example, the feature is on chromosome 12.
    -  **Example Value**: ``chr12``

2.  **Start Position** (``chromStart``):

    -  The starting position of the feature on the chromosome. This is a
       0-based coordinate, meaning it starts counting from 0.
    -  **Example Value**: ``25205243``

3.  **End Position** (``chromEnd``):

    -  The ending position of the feature on the chromosome. This is a
       1-based coordinate, meaning it starts counting from 1.
    -  **Example Value**: ``25205244``

4.  **Name** (``name``):

    -  This column typically contains a label or identifier for the
       feature. The possible values for this column in your BED file can
       be summarized as follows:

       -  **Methylation and Base Modifications:** 
       
          - ``'m'`` - Methylcytosine (5mC) 
          - ``'h'`` - Hydroxymethylcytosine (5hmC) 
          - ``'f'`` - Formylcytosine (5fC) 
          - ``'c'`` - Carboxycytosine (5caC)
          - ``'a'`` - 6-Methyladenine (6mA) 
          - ``'g'`` - Hydroxymethyluracil (5hmU) 
          - ``'e'`` - Formyluracil (5fU) 
          - ``'b'`` - Carboxyuracil (5caU) 
          - ``'o'`` - OxoGuanine (8-oxoG)

       -  **Canonical Bases:**

          -  ``'C'`` - Any Cytosine
          -  ``'A'`` - Any Adenine
          -  ``'T'`` - Any Thymine/Uracil
          -  ``'G'`` - Any Guanine

       -  **ChEBI Codes (Chemical Entities of Biological Interest):**

          -  ``17802`` - Pseudouridine (a modification of uracil)
          -  ``21839`` - 4-Methylcytosine
          -  ``17596`` - Inosine
          -  ``16450`` - Deoxyuracil

    -  **Example Value**: ``a``

5.  **Score** (``score``):

    -  The ``score`` represents the number of reads that passed the
       filtering criteria for this position. These reads are considered
       “valid” after applying various thresholds, including base
       modification thresholds and general quality thresholds.
    -  In the given example, the ``score`` is 5, meaning 5 reads passed
       all filters and were used in further analysis for this position.
    -  **Example Value**: ``5``

6.  **Strand** (``strand``):

    -  This column indicates the strand of the DNA on which the feature
       is located. It can be either ``+`` for the positive strand or
       ``-`` for the negative strand.
    -  **Example Value**: ``-``

7.  **Thick Start** (``thickStart``):

    -  This column is often the same as the ``Start Position`` and is
       used in certain genome browsers to visually represent the start
       of a feature.
    -  **Example Value**: ``25205243``

8.  **Thick End** (``thickEnd``):

    -  This column is often the same as the ``End Position`` and is used
       in certain genome browsers to visually represent the end of a
       feature.
    -  **Example Value**: ``25205244``

9.  **Color** (``color``):

    -  This column is used to specify the color for visualizing the
       feature in a genome browser. The color is usually represented in
       RGB format.
    -  **Example Value**: ``255,0,0`` (red)

10. **Valid Coverage** (``valid_coverage``):

-  The ``valid_coverage`` represents the number of reads that were
   considered valid for analysis after filtering. This includes
   filtering for base quality, mapping quality, and any
   modification-specific thresholds.
-  In the provided example, ``valid_coverage`` is 5, meaning 5 reads
   passed all the filters and were used to determine whether a base
   modification occurred.
-  This is typically the same as the ``score`` because both represent
   the number of reads that passed filtering.
-  **Example Value**: ``5``

11. **Percent Modified** (``percent_modified``):

-  This column indicates the percentage of valid reads that were
   identified as having the specific base modification. It is calculated
   by dividing the ``count_modified`` by the ``valid_coverage`` and then
   multiplying by 100.
-  In the given example, ``percent_modified`` is 40.00%, which means
   that 40% of the valid reads were detected as modified.
-  **Formula**: ``percent_modified`` = (``count_modified`` / ``valid_coverage``) × 100

-  **Example Value**: ``40.00``

12. **Count Modified** (``count_modified``):

-  The ``count_modified`` column shows the number of reads that were
   identified as having the specific modification at this position. In
   this example, 2 out of the 5 valid reads were detected as modified.
-  **Example Value**: ``2``

13. **Count Canonical** (``count_canonical``):

-  This column represents the number of reads that were identified as
   canonical (unmodified) at this position. In this example, 3 out of
   the 5 valid reads were determined to be unmodified.
-  **Example Value**: ``3``

14. **Count Other Mode** (``count_other_mode``):

-  This column represents the count of reads that were identified with
   modifications other than the primary one being analyzed. In your
   example, this value is 0, meaning no reads showed other
   modifications.
-  **Example Value**: ``0``

15. **Count Delete** (``count_delete``):

-  The ``count_delete`` column shows the number of reads that had a
   deletion at this position, meaning that a base was missing in those
   reads. In the example, there are no deletions at this site.
-  **Example Value**: ``0``

16. **Count Fail** (``count_fail``):

-  This column represents the number of reads that failed to pass
   quality filters at this position. These reads were not included in
   the ``valid_coverage``. In your example, 8 reads failed the quality
   checks.
-  **Example Value**: ``8``

17. **Count Diff** (``count_diff``):

-  The ``count_diff`` column represents the count of reads that had
   differences between the modification call and the reference genome.
   This indicates how many reads disagreed with the reference sequence
   at this position. In this example, there are no differences.
-  **Example Value**: ``0``

18. **Count NoCall** (``count_nocall``):

-  The ``count_nocall`` column indicates the number of reads where no
   call could be made, possibly due to low confidence or ambiguous
   signals. In this example, no reads were classified as ``NoCall``.
-  **Example Value**: ``0``