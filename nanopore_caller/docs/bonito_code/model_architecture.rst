Model Architecture
==================

**Model Type:** ``CTC-CRF`` (Connectionist Temporal Classification - Conditional Random Fields)

Model Components
----------------

1. **Labels:**

   - Alphabet: ``["N", "A", "C", "G", "T"]``

2. **Input:**

   - Features: ``1``

3. **QScore:**

   - Bias: ``0.0``
   - Scale: ``1.0``

4. **Encoder Configuration:**

   - Stride: ``5``
   - Window Length: ``19``
   - Scale: ``5.0``
   - Features: ``768``
   - RNN Type: ``LSTM``
   - Activation: ``Swish``
   - Blank Score: ``2.0``
   - Number of Layers: ``5``
   - First Convolution Size: ``4``
   - Normalization: ``None``

Encoder Layers
--------------

- **Convolutional Layers:**

  - Conv1: In Channels: ``1``, Out Channels: ``4``, Kernel Size: ``5``, Stride: ``1``, Activation: ``Swish``

  - Conv2: In Channels: ``4``, Out Channels: ``16``, Kernel Size: ``5``, Stride: ``1``, Activation: ``Swish``

  - Conv3: In Channels: ``16``, Out Channels: ``768``, Kernel Size: ``19``, Stride: ``5``, Activation: ``Swish``

- **Recurrent Layers:**

  - 5 LSTM Layers with ``768`` features each, alternating directions (reverse for odd layers)

- **Linear CRF Encoder:**

  - Features: ``768``
  - Alphabet Size: ``5`` (number of labels)
  - State Length: ``5``
  - Activation: ``Tanh``
  - Scale: ``5.0``
  - Blank Score: ``2.0``
  - Expand Blanks: ``True``

SeqDistModel
------------

- **Sequence Distribution Model (CTC-CRF):**

  - State Length: ``5``
  - Alphabet: ``["N", "A", "C", "G", "T"]``
  - Base Count: ``4`` (number of bases excluding 'N')
  - Index Array: Precomputed indices for CRF transitions

- **Methods:**

  - ``logZ``: Computes log partition function using sparse representation.

  - ``normalise``: Normalizes scores by subtracting log partition function.

  - ``forward_scores`` and ``backward_scores``: Compute forward and backward scores for sequences.

  - ``compute_transition_probs``: Computes transition probabilities for the CRF.

  - ``reverse_complement``: Generates the reverse complement of the scores.

  - ``viterbi``: Computes the Viterbi alignments.

  - ``path_to_str``: Converts a path to a string using the alphabet.

  - ``prepare_ctc_scores``: Prepares scores for CTC loss computation.

  - ``ctc_loss``: Computes the CTC loss.

  - ``ctc_viterbi_alignments``: Computes Viterbi alignments for CTC.

Model Class
-----------

- **Initialization:**

  - Configures the encoder and sequence distribution model based on the provided configuration.

- **Forward Pass:**

  - Passes the input through the encoder.

- **Decoding:**

  - Decodes batch and individual sequences using Viterbi algorithm and path-to-string conversion.

- **Loss Computation:**

  - Computes the CTC loss using the sequence distribution model.

- **KOI LSTM Update:**

  - Updates the encoder graph for KOI LSTM using provided batch size, chunk size, and quantization flag.

Additional Details
------------------

- **Global Normalization:**

  - State Length: ``5``

- **Use of KOI LSTM:**

  - The model can update the encoder using KOI LSTM for optimized performance.
