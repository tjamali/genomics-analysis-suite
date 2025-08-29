Bonito Basecalling Script
=========================

Overview
--------

This README explains the ``basecaller.py`` file located in the *cli* folder of the Bonito package. This script performs basecalling using the Bonito tool. It handles various tasks such as initializing configurations, reading data, aligning sequences, and writing output in different formats. Below is a detailed explanation of each part of the script.

Main Function Definition
------------------------

.. code-block:: python

    def main(args):

**Explanation**:
This defines the main function that takes ``args`` as an argument, which contains the command-line arguments passed to the script.

Initialization
--------------

.. code-block:: python

    # Initialize random seeds
    init(args.seed, args.device)

**Explanation**:
Initializes random seeds and sets up the device configuration for reproducibility and ensuring consistent behavior.

Reader Object Creation
----------------------

.. code-block:: python

    try:
        # Create a Reader object to read files from the specified directory
        reader = Reader(args.reads_directory, args.recursive)
        sys.stderr.write("> reading %s\n" % reader.fmt)
    except FileNotFoundError:
        # Handle the case where no suitable files are found in the directory
        sys.stderr.write("> error: no suitable files found in %s\n" % args.reads_directory)
        exit(1)

**Explanation**:
Attempts to create a ``Reader`` object to read files from the specified directory. If no suitable files are found, it prints an error message and exits.
This object determines the file format in the given directory and provides methods (``get_reads`` and ``get_read_groups``) to retrieve reads and read groups from the files.


Determine Output Format
-----------------------

.. code-block:: python

    # Determine the output format 
    fmt = biofmt(aligned=args.reference is not None)

**Explanation**:
Determine the output format based on the alignment status and the standard output, using the ``biofmt`` function.

Validate Reference File Format
------------------------------

.. code-block:: python

    if args.reference and args.reference.endswith(".mmi") and fmt.name == "cram":
        sys.stderr.write("> error: reference cannot be a .mmi when outputting cram\n")
        exit(1)
    elif args.reference and fmt.name == "fastq":
        # Warn if a reference is used with FASTQ output
        sys.stderr.write(f"> warning: did you really want {fmt.aligned} {fmt.name}?\n")
    else:
        # Inform the user about the output format
        sys.stderr.write(f"> outputting {fmt.aligned} {fmt.name}\n")

**Explanation**:
Validates the reference file format for CRAM output and issues warnings or information messages based on the reference and output format.

Model Directory Check and Download
----------------------------------

.. code-block:: python

    # Check if the model directory exists, download if not
    if args.model_directory in models and not (__models_dir__ / args.model_directory).exists():
        sys.stderr.write("> downloading model\n")
        Downloader(__models_dir__).download(args.model_directory)

**Explanation**:
Checks if the model directory exists. If not, it downloads the necessary model using the ``Downloader`` class.

Load Model
----------

.. code-block:: python

    sys.stderr.write(f"> loading model {args.model_directory}\n")
    try:
        # Load the specified model with provided configurations
        model = load_model(
            args.model_directory,
            args.device,
            weights=args.weights if args.weights > 0 else None,
            chunksize=args.chunksize,
            overlap=args.overlap,
            batchsize=args.batchsize,
            quantize=args.quantize,
            use_koi=True,
        )
        model = model.apply(fuse_bn_)
    except FileNotFoundError:
        # Handle the case where the model fails to load
        sys.stderr.write(f"> error: failed to load {args.model_directory}\n")
        sys.stderr.write(f"> available models:\n")
        for model in sorted(models):
            sys.stderr.write(f" - {model}\n")
        exit(1)

**Explanation**:
Attempts to load the specified model with provided configurations. If the model fails to load, it prints an error message and lists available models before exiting.

Verbose Mode and Basecall Function Loading
------------------------------------------

.. code-block:: python

    # If verbose mode is enabled, print model basecaller parameters
    if args.verbose:
        sys.stderr.write(f"> model basecaller params: {model.config['basecaller']}\n")

    # Load the basecall function from the specified model directory
    basecall = load_symbol(args.model_directory, "basecall")

**Explanation**:
If verbose mode is enabled, it prints the model basecaller parameters. Then, it loads the basecall function from the specified model directory.

Load Modified Base Model
------------------------

.. code-block:: python

    mods_model = None
    if args.modified_base_model is not None or args.modified_bases is not None:
        sys.stderr.write("> loading modified base model\n")
        # Load the modified base model with the specified configurations
        mods_model = load_mods_model(
            args.modified_bases, args.model_directory, args.modified_base_model,
            device=args.modified_device,
        )
        sys.stderr.write(f"> {mods_model[1]['alphabet_str']}\n")

**Explanation**:
Loads the modified base model if specified and prints the alphabet string of the modified model.

Load Reference
--------------

.. code-block:: python

    if args.reference:
        sys.stderr.write("> loading reference\n")
        # Load the reference using the specified aligner preset
        aligner = Aligner(args.reference, preset=args.mm2_preset)
        if not aligner:
            sys.stderr.write("> failed to load/build index\n")
            exit(1)
    else:
        aligner = None

**Explanation**:
Loads the reference using the specified aligner preset. If the aligner fails to load or build the index, it prints an error message and exits.

Check for CTC Training Data Requirement
---------------------------------------

.. code-block:: python

    # Check if CTC training data should be saved and if a reference is provided
    if args.save_ctc and not args.reference:
        sys.stderr.write("> a reference is needed to output ctc training data\n")
        exit(1)

**Explanation**:
Checks if CTC training data should be saved and if a reference is provided. If not, it prints an error message and exits.

Determine Read Groups
---------------------

.. code-block:: python

    # Determine the read groups if the output format is not FASTQ
    if fmt.name != 'fastq':
        groups, num_reads = reader.get_read_groups(
            args.reads_directory,
            args.model_directory,
            n_proc=8,
            recursive=args.recursive,
            read_ids=column_to_set(args.read_ids),
            skip=args.skip,
            cancel=process_cancel()
        )
    else:
        # If output format is FASTQ, set groups to an empty list and num_reads to None
        groups = []
        num_reads = None

**Explanation**:
Determines the read groups if the output format is not FASTQ. If the format is FASTQ, it sets groups to an empty list and ``num_reads`` to ``None``.

Retrieve Reads
--------------

.. code-block:: python

    # Retrieve the reads from the specified directory
    reads = reader.get_reads(
        args.reads_directory,
        n_proc=8,
        recursive=args.recursive,
        read_ids=column_to_set(args.read_ids),
        skip=args.skip,
        do_trim=not args.no_trim,
        scaling_strategy=model.config.get("scaling"),
        norm_params=(model.config.get("standardisation")
                     if (model.config.get("scaling") and
                         model.config.get("scaling").get("strategy") == "pa")
                     else model.config.get("normalisation")
                     ),
        cancel=process_cancel()
    )

**Explanation**:
Retrieves the reads from the specified directory, applying various parameters for processing, such as trimming, scaling strategy, and normalization parameters. It also handles the case for canceling the operation if needed.

Verbose Mode Read Scaling
-------------------------

.. code-block:: python

    if args.verbose:
        # If verbose mode is enabled, print the read scaling configuration
        sys.stderr.write(f"> read scaling: {model.config.get('scaling')}\n")

**Explanation**:
If verbose mode is enabled, prints the read scaling configuration.

Limit Maximum Reads
-------------------

.. code-block:: python

    if args.max_reads:
        # Limit the number of reads processed to the maximum specified
        reads = take(reads, args.max_reads)
        if num_reads is not None:
            num_reads = min(num_reads, args.max_reads)

**Explanation**:
Limits the number of reads processed to the maximum specified by the user.

Save CTC Data
-------------

.. code-block:: python

    if args.save_ctc:
        # If saving CTC data, create chunks from the reads
        reads = (
            chunk for read in reads
            for chunk in read_chunks(
                read,
                chunksize=model.config["basecaller"]["chunksize"],
                overlap=model.config["basecaller"]["overlap"]
            )
        )
        ResultsWriter = CTCWriter  # Use CTCWriter for writing results
    else:
        ResultsWriter = Writer  # Use standard Writer for writing results

**Explanation**:
Chooses the appropriate writer based on whether CTC data is being saved. If ``args.save_ctc`` is true, it uses ``CTCWriter``; otherwise, it uses the standard ``Writer``.

Basecall the Reads
------------------

.. code-block:: python

    # Basecall the reads using the specified model and parameters
    results = basecall(
        model, reads, reverse=args.revcomp, rna=args.rna,
        batchsize=model.config["basecaller"]["batchsize"],
        chunksize=model.config["basecaller"]["chunksize"],
       