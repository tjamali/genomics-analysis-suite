Evaluation Code Explanation
~~~~~~~~~~~~~~~~~~~~~~~~~~~

This markdown file explains the evaluation script step by step,
detailing what files and functions from ``bonito.data`` and
``bonito.util`` are necessary for the evaluation process.

--------------

1. **Initialization and Argument Parsing**
------------------------------------------

Before any evaluation can take place, the script begins by parsing
arguments and initializing the environment:

.. code:: python

   poas = []
   init(args.seed, args.device)

-  **init(seed, device)**: Initializes random number generators and sets
   up CuDNN for reproducibility. This is crucial for ensuring consistent
   results across different runs.

2. **Loading Data**
-------------------

The script loads data, either from pre-saved numpy files or by executing
a script. This step is essential for preparing the data that will be fed
into the model:

.. code:: python

   print("* loading data")
   try:
       train_loader_kwargs, valid_loader_kwargs = load_numpy(args.chunks, args.directory)
   except FileNotFoundError:
       train_loader_kwargs, valid_loader_kwargs = load_script(
           args.directory,
           seed=args.seed,
           chunks=args.chunks,
           valid_chunks=args.chunks
       )

-  **load_numpy(chunks, directory)**: Loads training and validation
   datasets from numpy files in the specified directory. The numpy files
   (``chunks.npy``, ``references.npy``, ``reference_lengths.npy``) must
   be present in the directory.
-  **load_script(directory, seed, chunks, valid_chunks)**: If the numpy
   files are not found, a script is loaded and executed to generate the
   data. The script should be located in the specified directory and
   named as per the default or specified ``name`` parameter in
   ``load_script``.

These functions return keyword arguments used to create DataLoaders
later in the script.

3. **DataLoader Setup**
-----------------------

The DataLoader is set up to handle batches of data efficiently during
evaluation:

.. code:: python

   dataloader = DataLoader(
       batch_size=args.batchsize, num_workers=4, pin_memory=True,
       **valid_loader_kwargs
   )

-  **DataLoader**: Handles batching, shuffling, and loading of the data
   during model evaluation. The ``batch_size`` and other parameters
   ensure optimal performance during data loading.

4. **Loading the Model**
------------------------

The script loads the model for evaluation:

.. code:: python

   model = load_model(args.model_directory, args.device, weights=w)
   mean = model.config.get("standardisation", {}).get("mean", 0.0)
   stdev = model.config.get("standardisation", {}).get("stdev", 1.0)

-  **load_model(directory, device, weights)**: Loads the model’s
   configuration and weights from the specified directory. The
   configuration includes model parameters and settings, while the
   weights are the learned parameters used for inference.
-  **Standardization Parameters**: The mean and standard deviation are
   extracted from the model’s configuration to standardize the input
   data.

5. **Model Evaluation**
-----------------------

The script performs the evaluation by running the data through the model
and calculating the accuracy:

.. code:: python

   for data, target, *_ in dataloader:
       data = (data - mean) / stdev

       targets.extend(torch.unbind(target, 0))
       if half_supported():
           data = data.type(torch.float16).to(args.device)
       else:
           data = data.to(args.device)

       log_probs = model(data)

-  **Data Standardization**: The input data is standardized using the
   mean and standard deviation extracted earlier.
-  **half_supported()**: Checks if the device supports half-precision
   floating-point format, which can improve performance on compatible
   GPUs.
-  **log_probs = model(data)**: The model processes the input data and
   outputs log probabilities for each class.

Sequence Decoding
~~~~~~~~~~~~~~~~~

.. code:: python

   if hasattr(model, 'decode_batch'):
       seqs.extend(model.decode_batch(log_probs))
   else:
       seqs.extend([model.decode(p) for p in permute(log_probs, 'TNC', 'NTC')])

-  **decode_batch**: If the model has a batch decoding method, it’s used
   to decode the output sequences.
-  **permute**: Permutes the output tensor from one layout to another,
   ensuring it matches the expected input for decoding.

6. **Accuracy Calculation**
---------------------------

After decoding, the script calculates the accuracy of the model’s
predictions:

.. code:: python

   refs = [decode_ref(target, model.alphabet) for target in targets]
   accuracies = [accuracy_with_cov(ref, seq) if len(seq) else 0. for ref, seq in zip(refs, seqs)]

-  **decode_ref**: Converts the encoded reference sequences back into
   string form.
-  **accuracy_with_cov**: Calculates the accuracy between the reference
   and predicted sequences, considering minimum coverage.

7. **Optional: POA (Partial Order Alignment)**
----------------------------------------------

If the ``--poa`` argument is provided, the script performs a consensus
sequence generation using POA:

.. code:: python

   if args.poa:
       poas.append(sequences)
       ...
       consensuses = poa(poas)
       accuracies = list(starmap(accuracy_with_cov, zip(refs, consensuses)))

-  **poa**: Generates consensus sequences from groups of sequences.
-  **starmap**: Maps the accuracy function over pairs of references and
   consensus sequences.

8. **Performance Metrics**
--------------------------

Finally, the script outputs key performance metrics:

.. code:: python

   print("* mean      %.2f%%" % np.mean(accuracies))
   print("* median    %.2f%%" % np.median(accuracies))
   print("* time      %.2f" % duration)
   print("* samples/s %.2E" % (args.chunks * data.shape[2] / duration))

-  **Mean and Median Accuracy**: The average and median accuracy across
   all sequences.
-  **Time and Throughput**: The total time taken and the number of
   samples processed per second.

--------------
