Introduction to BED Files
=========================

This tutorial will introduce you to the BED file format, its structure,
usage, and how it complements BAM files in genomic analyses.



1. What is a BED File?
----------------------

A BED (Browser Extensible Data) file is a simple, tab-delimited text
file used to define genomic regions. It’s widely used in bioinformatics
to represent features such as genes, exons, regulatory elements, or any
other regions of interest on a genome.

Unlike BAM files, which store alignments of sequence reads, BED files
store information about regions on the genome, often used to annotate,
compare, or visualize these regions.


2. BED File Structure
---------------------

A BED file typically consists of 3 to 12 columns, each serving a
specific purpose. The first three columns are mandatory, while the
others are optional.

**Mandatory Columns:**
~~~~~~~~~~~~~~~~~~~~~~

1. | **chrom** (Chromosome):
   | The chromosome name, e.g., ``chr1``, ``chrX``, ``chrM``.

2. | **chromStart** (Start Position):
   | The start position of the feature on the chromosome.

3. | **chromEnd** (End Position):
   | The end position of the feature on the chromosome.

**Optional Columns:**
~~~~~~~~~~~~~~~~~~~~~

4.  | **name**:
    | The name or identifier of the feature (e.g., gene name).

5.  | **score**:
    | A score between 0 and 1000, often representing confidence or
      significance.

6.  | **strand**:
    | The strand on which the feature is located (``+``, ``-``, or
      ``.``).

7.  | **thickStart**:
    | The start position of the thick part, typically indicating coding
      regions.

8.  | **thickEnd**:
    | The end position of the thick part.

9.  | **itemRgb**:
    | RGB value defining the color for visualizing the feature (e.g.,
      ``255,0,0`` for red).

10. | **blockCount**:
    | The number of sub-features that are included as part of the main feature.

11. | **blockSizes**:
    | A comma-separated list of the sizes of each block.

12. | **blockStarts**:
    | A comma-separated list of start positions for each block, relative
      to the start of the main feature.

Example BED File
^^^^^^^^^^^^^^^^

.. list-table:: 
   :widths: 10 10 10 10 10 10 10 10 10 10 10 10
   :header-rows: 1

   * - Chrom
     - Start
     - End
     - Name
     - Score
     - Strand
     - Thick Start
     - Thick End
     - Item RGB
     - Block Count
     - Block Sizes
     - Block Starts
   * - chr1
     - 10,468
     - 10,469
     - 5mC
     - 904
     - \+
     - 10,468
     - 10,469
     - 0,0,0
     - 115
     - 79.81
     - 21
   * - chr1
     - 10,469
     - 10,470
     - 5mC
     - 880
     - \-
     - 10,469
     - 10,470
     - 0,0,0
     - 126
     - 88.29
     - 13
   * - chr1
     - 10,470
     - 10,471
     - 5mC
     - 913
     - \+
     - 10,470
     - 10,471
     - 0,0,0
     - 115
     - 87.62
     - 13
   * - chr1
     - 10,471
     - 10,472
     - 5mC
     - 873
     - \-
     - 10,471
     - 10,472
     - 0,0,0
     - 126
     - 82.73
     - 19

In this example:

-  **Chrom**: The chromosome (``chr1``).
-  **Start**: The start position on the chromosome (e.g., ``10,468``).
-  **End**: The end position on the chromosome (e.g., ``10,469``).
-  **Name**: The feature name (e.g., ``5mC``).
-  **Score**: The score for the feature (e.g., ``904``).
-  **Strand**: The strand (``+`` or ``-``).
-  **Thick Start**: The start of the thick part, typically the coding
   region (e.g., ``10,468``).
-  **Thick End**: The end of the thick part (e.g., ``10,469``).
-  **Item RGB**: The color value for visualization (e.g., ``0,0,0`` for
   black).
-  **Block Count**: The number of blocks (e.g., ``115``).
-  **Block Sizes**: The size of each block (e.g., ``79.81``).
-  **Block Starts**: The start positions for each block relative to
   ``chromStart`` (e.g., ``21``).

A BED file can be used in various genomic analyses, such as
annotating methylation sites (``5mC`` refers to 5-methylcytosine) on a
chromosome.


3. Comparing BED Files to BAM Files
-----------------------------------

-  **BED Files:**

   -  **Purpose:** Describe regions on the genome.
   -  **Format:** Text-based, easy to read and edit.
   -  **Typical Use:** Annotation, visualization, region comparison.
   -  **Common Tools:** ``bedtools``, ``UCSC Genome Browser``.

-  **BAM Files:**

   -  **Purpose:** Store aligned sequence reads.
   -  **Format:** Binary, efficient storage and retrieval.
   -  **Typical Use:** Sequence alignment, variant calling, read
      counting.
   -  **Common Tools:** ``samtools``, IGV (Integrative Genomics Viewer).

4. Common Uses of BED Files
---------------------------

1. **Intersecting Genomic Regions:**

   -  BED files are often used to find overlaps between different sets
      of genomic regions. For example, you can compare regions from a
      BED file against another to identify common regions.

   Example:

   .. code:: bash

      bedtools intersect -a regions1.bed -b regions2.bed > intersect.bed

2. **Annotating Genomic Regions:**

   -  BED files are used to annotate specific regions with features like
      gene names, functional annotations, or epigenetic marks.

3. **Visualization:**

   -  BED files can be loaded into genome browsers like the UCSC Genome
      Browser to visualize specific regions of interest alongside other
      genomic data.

5. Creating and Manipulating BED Files
--------------------------------------

**Creating a BED File:**
~~~~~~~~~~~~~~~~~~~~~~~~

You can manually create a BED file using any text editor. Here’s an
example of a simple BED file:

.. code:: plaintext

   chr1    1000    5000    Gene1   960    +
   chr2    2000    6000    Gene2   900    -
   chrX    3000    7000    Gene3   850    +

**Converting BAM to BED:**
~~~~~~~~~~~~~~~~~~~~~~~~~~

To convert a BAM file to a BED file, use the ``bedtools bamtobed``
command:

.. code:: bash

   bedtools bamtobed -i input.bam > output.bed

This command extracts the aligned regions from the BAM file and converts
them into BED format.


6. Conclusion
-------------

BED files are a fundamental format in bioinformatics for describing and
working with genomic regions. While BAM files are essential for storing
and processing sequence alignment data, BED files provide a
complementary role in annotating, comparing, and visualizing regions of
interest.

By understanding how to create, manipulate, and use BED files, you can
enhance your ability to analyze genomic data, especially when working in
conjunction with BAM files and related tools.
