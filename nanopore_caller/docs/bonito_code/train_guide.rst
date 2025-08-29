Bonito Training Script
======================

This script is designed for training deep learning models using the
Bonito framework. The script integrates several utility functions, data
loaders, model initialization, and training procedures to facilitate the
training of a Bonito model. Below is an explanation of each part of the
script.

1. Script Overview
------------------

The script starts by importing necessary libraries and modules,
including the Bonito package components (``bonito.data``,
``bonito.util``, and ``bonito.training``). It also imports common
libraries like ``argparse``, ``torch``, and ``os``.

2. Argument Parsing
-------------------

The script uses ``argparse`` to define and parse command-line arguments,
allowing users to customize various aspects of the training process.
Some of the key arguments include: 

- ``training_directory``: Directory to save training outputs. 

- ``--config``: Path to the model configuration file. 

- ``--pretrained``: Path to a pretrained model directory. 

- ``--device``: Specifies the device for training (e.g.,‘cpu’ or ‘cuda’). 

- ``--lr``: Learning rate. 

- ``--epochs``: Number of training epochs. 

- ``--batch``: Batch size. 

- ``--chunks``: Number of chunks for training. 

- ``--valid-chunks``: Number of chunks for validation. 

- ``--no-amp``: Disable automatic mixed precision. 

- ``--restore-optim``: Restore the optimizer state from a previous training session.

3. Main Function
----------------

The ``main(args)`` function is the core of the script and is responsible
for setting up and executing the training process.

.. code:: python

   def main(args):

3.1. Data Directory Setup
~~~~~~~~~~~~~~~~~~~~~~~~~

If the ``directory`` argument is not provided, the script attempts to
locate an example dataset within the Bonito package’s ``data``
directory. I added this part myself to handle situations where the 
user does not provide the training dataset path.

.. code:: python

       if not args.directory:
           data_folder = os.path.join(package_dir, 'data')
           items = os.listdir(data_folder)
           example_data_dirs = [item for item in items if
                                os.path.isdir(os.path.join(data_folder, item)) and item.startswith('example_data')]
           if not example_data_dirs:
               raise FileNotFoundError("No dataset directory has been specified, nor is there a directory starting with 'example_data' in the 'bonito/data/' folder.")
           else:
               print("Found 'example_data' directories:", example_data_dirs)
               args.directory = Path(os.path.join(data_folder, example_data_dirs[0]))

3.2. Working Directory Setup
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The script sets up the working directory (``workdir``) where training
outputs, including model checkpoints and logs, will be saved. If the
directory already exists and the ``--force`` argument is not specified,
the script will exit with an error to prevent accidental overwriting of
previous results.

.. code:: python

       workdir = os.path.expanduser(args.training_directory)

       if os.path.exists(workdir) and not args.force:
           print("[error] %s exists, use -f to force continue training." % workdir)
           exit(1)

3.3. Training Environment Initialization
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The ``init()`` function is used to initialize the training environment,
including setting random seeds for reproducibility and configuring the
device (CPU or GPU).

.. code:: python

       init(args.seed, args.device, (not args.nondeterministic))
       device = torch.device(args.device)

3.4. Model Configuration and Loading
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

If a pretrained model is specified, its configuration is loaded, and the
corresponding model is initialized using the ``load_model()`` function.
Otherwise, the script loads the model configuration from the provided
``--config`` file.

.. code:: python

       if not args.pretrained:
           config = toml.load(args.config)
       else:
           dirname = args.pretrained
           if not os.path.isdir(dirname) and os.path.isdir(os.path.join(__models_dir__, dirname)):
               dirname = os.path.join(__models_dir__, dirname)
           pretrain_file = os.path.join(dirname, 'config.toml')
           config = toml.load(pretrain_file)
           if 'lr_scheduler' in config:
               print(f"[ignoring 'lr_scheduler' in --pretrained config]")
               del config['lr_scheduler']

       print(config)

       print("[loading model]")
       if args.pretrained:
           print("[using pretrained model {}]".format(args.pretrained))
           model = load_model(args.pretrained, device, half=False)
       else:
           model = load_symbol(config, 'Model')(config)

3.5. Data Loading
~~~~~~~~~~~~~~~~~

The script attempts to load training and validation data using the
``load_numpy()`` function. If the specified data directory does not
contain the necessary files, it falls back to loading a custom dataset
script using the ``load_script()`` function.

.. code:: python

       print("[loading data]")
       try:
           train_loader_kwargs, valid_loader_kwargs = load_numpy(
               args.chunks, args.directory, valid_chunks=args.valid_chunks
           )
       except FileNotFoundError:
           train_loader_kwargs, valid_loader_kwargs = load_script(
               args.directory,
               seed=args.seed,
               chunks=args.chunks,
               valid_chunks=args.valid_chunks,
               n_pre_context_bases=getattr(model, "n_pre_context_bases", 0),
               n_post_context_bases=getattr(model, "n_post_context_bases", 0),
           )

3.6. DataLoader Setup
~~~~~~~~~~~~~~~~~~~~~

DataLoaders are set up for both training and validation datasets using
the ``torch.utils.data.DataLoader`` class, with parameters such as batch
size and number of workers specified by the user.

.. code:: python

       loader_kwargs = {
           "batch_size": args.batch, "num_workers": args.num_workers, "pin_memory": True
       }
       train_loader = DataLoader(**loader_kwargs, **train_loader_kwargs)
       valid_loader = DataLoader(**loader_kwargs, **valid_loader_kwargs)

       print('train dataloader size:', len(train_loader), '--- valid dataloader size:', len(valid_loader))

3.7. Learning Rate Scheduler
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

If a learning rate scheduler is defined in the model configuration, it
is loaded and applied to the optimizer. The script supports custom
schedulers specified in the model configuration file.

.. code:: python

       if config.get("lr_scheduler"):
           sched_config = config["lr_scheduler"]
           lr_scheduler_fn = getattr(
               import_module(sched_config["package"]), sched_config["symbol"]
           )(**sched_config)
       else:
           lr_scheduler_fn = None

3.8. Trainer Initialization
~~~~~~~~~~~~~~~~~~~~~~~~~~~

The ``Trainer`` class from ``bonito.training`` is initialized with the
model, device, DataLoaders, and other training configurations. The
``Trainer`` class handles the core training loop, including gradient
accumulation, mixed precision training, and model validation.

.. code:: python

       trainer = Trainer(
           model, device, train_loader, valid_loader,
           use_amp=half_supported() and not args.no_amp,
           lr_scheduler_fn=lr_scheduler_fn,
           restore_optim=args.restore_optim,
           save_optim_every=args.save_optim_every,
           grad_accum_split=args.grad_accum_split,
           quantile_grad_clip=args.quantile_grad_clip
       )

This code block initializes the ``Trainer`` object, which is responsible
for orchestrating the entire training process. It sets up automatic
mixed precision (AMP) if supported, manages learning rate scheduling,
and optionally restores the optimizer state if resuming training from a
checkpoint.

3.9. Training Execution
~~~~~~~~~~~~~~~~~~~~~~~

The ``fit()`` method of the ``Trainer`` class is called to start the
training process. This method trains the model for the specified number
of epochs, saves model checkpoints, and logs training and validation
metrics.

.. code:: python

       # Parse and set learning rate
       if ',' in args.lr:
           lr = [float(x) for x in args.lr.split(',')]
       else:
           lr = float(args.lr)
       optim_kwargs = config.get("optim", {})

       # Start training
       trainer.fit(workdir, args.epochs, lr, **optim_kwargs)

In this part, the script parses the learning rate (``lr``) provided by
the user. If multiple learning rates are specified (as a comma-separated
list), they are parsed into a list of floats. The ``fit()`` method of
the ``Trainer`` class is then called, which starts the actual training
process, handling the training loop over the specified number of epochs,
applying the learning rate, and saving model checkpoints.

4. Example Usage
----------------

To run the training script, use the following command:

.. code:: bash

   bonito train -f MODEL_OUTPUT_PATH --directory DATASET_PATH --config CONFIG_PATH --lr 2e-3 --epochs 15

Replace the arguments as needed to customize the training process.
