Comprehensive Guide to BAM Files
================================

Contents
--------

1. **Introduction**

   -  Overview of BAM/CRAM files and their significance in genomic data
      analysis.
   -  Introduction to IGV and Samtools.
   -  Benefits of visualizing BAM files with IGV.
   -  Advantages of using Samtools for BAM file manipulation.

2. **Understanding BAM File Content**

   -  Viewing BAM files using IGV.

      -  Explanation of IGV interface and features.
      -  Detailed breakdown of BAM file components in IGV.

   -  Viewing and understanding BAM files using Samtools.

      -  Header
      -  Alignment
      -  Commands for inspecting BAM file contents.

3. **Using Samtools for Genomic Data Analysis**

   -  Installation and prerequisites.
   -  Common commands and their usage:

      -  Converting CRAM to BAM with multiple threads.
      -  Sorting BAM files.
      -  Indexing BAM files.
      -  Generating basic statistics.
      -  Extracting specific regions.
      -  Filtering BAM files by quality.
      -  Merging multiple BAM files.
      -  Removing duplicates.

1. Introduction
---------------

Overview of BAM/CRAM Files
~~~~~~~~~~~~~~~~~~~~~~~~~~

BAM (Binary Alignment/Map) and CRAM (Compressed Reference-Aligned Map)
files are binary formats used to store sequence data that has been
aligned to a reference genome. These formats are essential for efficient
storage and processing of large genomic datasets. You can also visit `EPI2ME
<https://labs.epi2me.io/reviewing-bam/>`__ .

Introduction to IGV and Samtools
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-  **IGV (Integrative Genomics Viewer)** is a high-performance,
   easy-to-use visualization tool that enables researchers to view and
   explore genomic data interactively. It supports various file formats,
   including BAM, and provides detailed information about alignments and
   variations.
-  **Samtools** is a powerful suite of programs designed to manipulate
   and analyze BAM, SAM, and CRAM files. It supports various operations
   such as viewing, sorting, indexing alignments, generating statistics,
   and converting between formats.

Benefits of Visualizing BAM Files with IGV
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-  Interactive exploration of genomic data.
-  Detailed visualization of read alignments and annotations.
-  Easy navigation across different genomic regions.

Advantages of Using Samtools for BAM File Manipulation
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-  Efficient processing of large datasets.
-  Comprehensive suite of tools for various genomic data operations.
-  Capability to automate and script workflows for high-throughput
   analysis.

2. Understanding BAM File Content
---------------------------------

Viewing BAM Files Using IGV
~~~~~~~~~~~~~~~~~~~~~~~~~~~

Explanation of IGV Interface and Features
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

1. **Launch IGV**:

   -  Open IGV from your applications menu or by typing ``igv`` in the
      terminal if IGV is installed properly.

2. **Set Reference Genome**:

   -  Select the reference genome you want to use from the drop-down
      menu at the top left. For human data, select ``Human hg19`` (or
      any other appropriate reference genome).

3. **Load BAM File**:

   -  Go to ``File`` -> ``Load from File...``.
   -  Navigate to the directory where you downloaded the BAM and BAI
      files.
   -  Select the BAM file.

4. **View Alignment**:

   -  The BAM file will load, and you should be able to see the aligned
      reads on the IGV interface.
   -  You can zoom in and out and navigate through different regions of
      the chromosome to inspect the alignment.
      
Detailed Breakdown of BAM File Components in IGV
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

When you click on a read in IGV, a window pops up with detailed
information. Here is an explanation of each part:

-  **Read name**: Unique identifier for the read.
-  **Sample**: Identifier for the sample the read came from.
-  **Library**: The sequencing library used.
-  **Read group**: Identifier for the group of reads processed together.
-  **Read length**: Length of the read in base pairs.
-  **Flags**: Bitwise flag providing alignment information.
-  **Mapping**: Indicates primary alignment and mapping quality score.
-  **Reference span**: The region on the reference genome where the read
   aligns.
-  **CIGAR**: Describes the alignment with the reference genome.
-  **Clipping**: Indicates if there is any clipping in the alignment.
-  **Mate information**: Includes mate is mapped, mate start, and second
   in pair.
-  **NM**: Number of mismatches with the reference sequence.
-  **CQ**: Quality scores for the read.
-  **CS**: Color space sequence tag.
-  **Hidden tags**: Additional alignment tags.
-  **Location and Base information**: Specific location on the reference
   genome and nucleotide base at the location with its quality value.

Viewing and Understanding BAM Files Using Samtools
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

A BAM (Binary Alignment/Map) file is a binary format for storing
sequence data that has been aligned to a reference genome. Here’s an
overview of its content structure:

Header
^^^^^^

1. **@HD (Header line)**

   -  **VN:** Format version. Required field.

      -  Example: ``VN:1.6``

   -  **SO:** Sorting order of alignments. Optional field.

      -  Possible values: ``unknown``, ``unsorted``, ``queryname``,
         ``coordinate``
      -  Example: ``SO:coordinate``

   -  **GO:** Grouping of alignments. Optional field.

      -  Possible values: ``none``, ``query``, ``reference``
      -  Example: ``GO:none``

2. **@SQ (Reference sequence dictionary)**

   -  **SN:** Reference sequence name. Required field.

      -  Example: ``SN:chr1``

   -  **LN:** Reference sequence length. Required field.

      -  Example: ``LN:248956422``

   -  **AH:** Alternate locus. Optional field.

      -  Example: ``AH:chr1_KI270706v1_random``

   -  **AN:** Alternative reference sequence names. Optional field.

      -  Example: ``AN:1``

   -  **AS:** Genome assembly identifier. Optional field.

      -  Example: ``AS:GRCh38``

   -  **M5:** MD5 checksum of the sequence. Optional field.

      -  Example: ``M5:1b22b98cdeb4a9304cb5d48026a85128``

   -  **SP:** Species. Optional field.

      -  Example: ``SP:Homo sapiens``

   -  **UR:** URI of the sequence. Optional field.

      -  Example: ``UR:file:/seq/references/GRCh38.fa``

3. **@RG (Read group)**

   -  **ID:** Read group identifier. Required field.

      -  Example: ``ID:group1``

   -  **BC:** Barcode sequence. Optional field.

      -  Example: ``BC:AGCTAA``

   -  **CN:** Name of sequencing center producing the read. Optional
      field.

      -  Example: ``CN:Broad Institute``

   -  **DS:** Description. Optional field.

      -  Example: ``DS:Paired-end sequencing``

   -  **DT:** Date the run was produced (ISO 8601 date/time). Optional
      field.

      -  Example: ``DT:2021-06-01T12:34:56Z``

   -  **FO:** Flow order. Optional field.

      -  Example: ``FO:ACGT``

   -  **KS:** The array of nucleotide bases that correspond to the key
      sequence of each read. Optional field.

      -  Example: ``KS:ATCG``

   -  **LB:** Library. Optional field.

      -  Example: ``LB:lib1``

   -  **PG:** Programs used for processing the read group. Optional
      field.

      -  Example: ``PG:bwa``

   -  **PI:** Predicted median insert size. Optional field.

      -  Example: ``PI:300``

   -  **PL:** Platform/technology used to produce the reads. Optional
      field.

      -  Possible values: ``CAPILLARY``, ``LS454``, ``ILLUMINA``,
         ``SOLID``, ``HELICOS``, ``IONTORRENT``, ``ONT``, ``PACBIO``
      -  Example: ``PL:ILLUMINA``

   -  **PM:** Platform model. Optional field.

      -  Example: ``PM:HiSeq2000``

   -  **PU:** Platform unit. Optional field.

      -  Example: ``PU:unit1``

   -  **SM:** Sample. Optional field.

      -  Example: ``SM:sample1``

4. **@PG (Program)**

   -  **ID:** Program identifier. Required field.

      -  Example: ``ID:bwa``

   -  **PN:** Program name. Optional field.

      -  Example: ``PN:bwa``

   -  **CL:** Command line. Optional field.

      -  Example: ``CL:bwa mem -t 8 ref.fa reads.fq``

   -  **PP:** Previous program identifier. Optional field.

      -  Example: ``PP:previous_program``

   -  **DS:** Description. Optional field.

      -  Example: ``DS:Alignment using BWA``

   -  **VN:** Program version. Optional field.

      -  Example: ``VN:0.7.17``

5. **@CO (Comment)**

   -  **Text:** Any comment text.

      -  Example: ``@CO This is a comment.``

These header lines provide metadata about the sequencing data and the
reference genome, which is essential for interpreting the alignment data
correctly.

Alignment
^^^^^^^^^

1.  **QNAME (Query template NAME)**

    -  Any string: Typically the name of the read or read pair.

2.  **FLAG (Bitwise FLAG)**

    -  Integer: A bitwise combination of flags indicating various
       properties of the read.

       -  ``0x1`` (1): Template having multiple segments in sequencing.
       -  ``0x2`` (2): Each segment properly aligned according to the
          aligner.
       -  ``0x4`` (4): Segment unmapped.
       -  ``0x8`` (8): Next segment in the template unmapped.
       -  ``0x10`` (16): SEQ being reverse complemented.
       -  ``0x20`` (32): SEQ of the next segment in the template being
          reverse complemented.
       -  ``0x40`` (64): The first segment in the template.
       -  ``0x80`` (128): The last segment in the template.
       -  ``0x100`` (256): Secondary alignment.
       -  ``0x200`` (512): Not passing filters, such as platform/vendor
          quality controls.
       -  ``0x400`` (1024): PCR or optical duplicate.
       -  ``0x800`` (2048): Supplementary alignment.

3.  **RNAME (Reference sequence NAME)**

    -  String: Name of the reference sequence (chromosome or contig) to
       which the read is aligned, e.g., ``chr1``, ``chr2``, ``chrX``,
       etc.
    -  ``*``: Indicates an unmapped read.

4.  **POS (1-based leftmost mapping POSition)**

    -  Integer: 1-based position where the read aligns to the reference
       sequence.
    -  ``0``: Indicates an unmapped read.

5.  **MAPQ (MAPping Quality)**

    -  Integer: Quality score (0-255) indicating the confidence in the
       alignment of the read.
    -  ``255``: Indicates that the mapping quality is not available.

6.  **CIGAR (CIGAR string)**

    -  String: Represents the alignment of the read to the reference
       sequence using specific operators:

       -  ``M``: Alignment match (can be a sequence match or mismatch).
       -  ``I``: Insertion to the reference.
       -  ``D``: Deletion from the reference.
       -  ``N``: Skipped region from the reference.
       -  ``S``: Soft clipping (clipped sequences present in SEQ).
       -  ``H``: Hard clipping (clipped sequences not present in SEQ).
       -  ``P``: Padding (silent deletion from padded reference).
       -  ``=``: Sequence match.
       -  ``X``: Sequence mismatch.

    -  ``*``: Indicates an unmapped read.

7.  **RNEXT (Reference name of the mate/next read)**

    -  String: Reference sequence name of the mate read.
    -  ``=``: Mate is on the same reference as the read.
    -  ``*``: Indicates no information about the mate read.

8.  **PNEXT (Position of the mate/next read)**

    -  Integer: 1-based position of the mate read’s alignment.
    -  ``0``: Indicates no information about the mate read.

9.  **TLEN (observed Template LENgth)**

    -  Integer: Observed template length, calculated as the distance
       between the ends of the mate reads.
    -  Positive: If the mate is downstream.
    -  Negative: If the mate is upstream.
    -  ``0``: Indicates no information about the template length.

10. **SEQ (Segment SEQuence)**

    -  String: The sequence of the read.
    -  ``*``: Indicates that the sequence is not stored in the BAM file.

11. **QUAL (Phred-scaled base QUALity+33)**

    -  String: ASCII-encoded base quality scores for the read.
    -  ``*``: Indicates that the quality scores are not stored.

12. **Optional Fields**

    -  Format: ``TAG:TYPE:VALUE``

       -  ``TAG``: Two-character string identifier for the tag.
       -  ``TYPE``: Single character indicating the data type:

          -  ``A``: Character.
          -  ``i``: Integer.
          -  ``f``: Float.
          -  ``Z``: String.
          -  ``H``: Hex string.
          -  ``B``: Byte array.

       -  ``VALUE``: The actual data.

    -  Examples:

       -  ``NM:i:1``: Number of mismatches (``NM``) with integer value
          (``i``) of 1.
       -  ``AS:i:23``: Alignment score (``AS``) with integer value
          (``i``) of 23.
       -  ``RG:Z:group1``: Read group (``RG``) with string value (``Z``)
          of ``group1``.

These columns and values provide comprehensive information about the
alignment of sequence reads to a reference genome, which is essential
for downstream analysis in bioinformatics.

Commands for Inspecting BAM File Contents
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Viewing BAM/CRAM Files
''''''''''''''''''''''

.. code:: bash

   samtools view yourfile.bam | less -S
   samtools view -T reference.fasta yourfile.cram | less -S

3. Using Samtools for Genomic Data Analysis
-------------------------------------------

Installation and Prerequisites
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Ensure ``samtools`` is installed on your system. Install using the
package manager or compile from source:

.. code:: bash

   sudo apt-get update
   sudo apt-get install samtools

Common Commands and Their Usage
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Converting CRAM to BAM with Multiple Threads
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

When converting a CRAM file to BAM, specifying the reference genome is
necessary if the CRAM file uses reference-based compression. You can
also speed up the process using multiple threads.

.. code:: bash

   samtools view -T reference.fasta -b -@ 4 -o output.bam input.cram

-  ``-T reference.fasta``: Specifies the reference genome file.
-  ``-b``: Output in BAM format.
-  ``-@ 4``: Use 4 threads.
-  ``-o output.bam``: Specifies the output BAM file.
-  ``input.cram``: The input CRAM file.

Sorting BAM Files
^^^^^^^^^^^^^^^^^

Sorting a BAM file is crucial for various downstream applications, such
as indexing.

.. code:: bash

   samtools sort -o sorted_output.bam input.bam

-  ``-o sorted_output.bam``: Specifies the sorted output BAM file.

To determine if a BAM file is sorted, you can check the header for specific indicators. 
Sorted BAM files typically have a @HD (header) line with a SO (sort order) tag indicating 
the sorting order. Common values for SO are coordinate, queryname, and unsorted.

Interpreting the Header:

- coordinate: Indicates the BAM file is sorted by coordinates.
- queryname: Indicates the BAM file is sorted by query names.
- unsorted: Indicates the BAM file is not sorted.

Here’s how you can check the header:

.. code:: bash

   samtools view -H yourfile.bam | grep '@HD'

Indexing BAM Files
^^^^^^^^^^^^^^^^^^

Indexing a BAM file allows quick access to specific regions of the
genome.

.. code:: bash

   samtools index sorted_output.bam

Generating Basic Statistics
^^^^^^^^^^^^^^^^^^^^^^^^^^^

To quickly check the alignment statistics of a BAM file, use
``samtools flagstat``.

.. code:: bash

   samtools flagstat sorted_output.bam

Extracting Specific Regions
^^^^^^^^^^^^^^^^^^^^^^^^^^^

To extract reads from a specific region in the BAM file:

.. code:: bash

   samtools view sorted_output.bam chr1:100000-200000

Filtering BAM Files by Quality
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: bash

   samtools view -b -q 30 sorted_output.bam -o filtered_output.bam

-  ``-q 30``: Keeps reads with a mapping quality of 30 or higher.
-  ``-b``: Output in BAM format.

Merging Multiple BAM Files
^^^^^^^^^^^^^^^^^^^^^^^^^^

If you have multiple BAM files, you can merge them into one.

.. code:: bash

   samtools merge merged_output.bam input1.bam input2.bam input3.bam

Removing Duplicates
^^^^^^^^^^^^^^^^^^^

To remove duplicate reads from a BAM file, use ``samtools markdup``.

.. code:: bash

   samtools markdup -r sorted_output.bam deduped_output.bam

-  ``-r``: Removes duplicates.

Example Workflow
----------------

Here is an example workflow that converts a CRAM file to a sorted,
indexed BAM file and then generates statistics:

.. code:: bash

   # Step 1: Convert CRAM to BAM with multiple threads
   samtools view -T reference.fasta -b -@ 4 -o example.bam example.cram

   # Step 2: Sort the BAM file
   samtools sort -o example_sorted.bam example.bam

   # Step 3: Index the sorted BAM file
   samtools index example_sorted.bam

   # Step 4: Generate alignment statistics
   samtools flagstat example_sorted.bam

Conclusion
----------

``samtools`` is a versatile tool for handling BAM and CRAM files,
offering functionalities from basic viewing to complex filtering and
statistics generation. This tutorial covered essential commands commonly
used in genomic data analysis workflows. Additionally, IGV provides an
interactive platform for visualizing and exploring BAM file content.

For more detailed information and advanced usage, refer to the official
``samtools`` documentation: `samtools official
documentation <http://www.htslib.org/doc/samtools.html>`__.
