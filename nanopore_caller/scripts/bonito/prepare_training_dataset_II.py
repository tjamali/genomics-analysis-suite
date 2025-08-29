#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Sun Aug  4 19:17:49 2024

@author: tjamali
"""

import numpy as np
from pathlib import Path
import matplotlib.pyplot as plt

# Paths to data directories
DATA_PATH_1 = Path('/restricted/projectnb/leshlab/net/tjamali/project/code/data/training/ctc-data/20230424_1302_3H_PAO89685_2264ba8c/subfolder_0/sup_qscore_0_acc_0.99/')
DATA_PATH_2 = Path('/restricted/projectnb/leshlab/net/tjamali/project/code/data/training/ctc-data/20230424_1302_3H_PAO89685_2264ba8c/subfolder_0/sup_qscore_30_acc_0.99/')
DATA_PATH_3 = Path('/restricted/projectnb/leshlab/net/tjamali/project/code/data/evaluation/20230428_subfolder_4/sup_qscore_30_acc_995')

# Load data from each directory using memmap
chunks_1 = np.load(DATA_PATH_1 / 'chunks.npy', mmap_mode='r')
refs_1 = np.load(DATA_PATH_1 / 'references.npy', mmap_mode='r')
lengths_1 = np.load(DATA_PATH_1 / 'reference_lengths.npy', mmap_mode='r')

chunks_2 = np.load(DATA_PATH_2 / 'chunks.npy', mmap_mode='r')
refs_2 = np.load(DATA_PATH_2 / 'references.npy', mmap_mode='r')
lengths_2 = np.load(DATA_PATH_2 / 'reference_lengths.npy', mmap_mode='r')

chunks_3 = np.load(DATA_PATH_3 / 'chunks.npy', mmap_mode='r')
refs_3 = np.load(DATA_PATH_3 / 'references.npy', mmap_mode='r')
lengths_3 = np.load(DATA_PATH_3 / 'reference_lengths.npy', mmap_mode='r')

# Print the shapes of the loaded arrays
print(chunks_1.shape)
print(chunks_2.shape)
print(chunks_3.shape)

# # Find the minimum length from the three chunks arrays
# min_length = min(chunks_1.shape[0], chunks_2.shape[0], chunks_3.shape[0])

# # Create new arrays with the truncated length
# new_chunks_1 = chunks_1[:min_length, :]
# new_chunks_2 = chunks_2[:min_length, :]
# new_chunks_3 = chunks_3[:min_length, :]

# new_refs_1 = refs_1[:min_length, :]
# new_refs_2 = refs_2[:min_length, :]
# new_refs_3 = refs_3[:min_length, :]

# new_lengths_1 = lengths_1[:min_length]
# new_lengths_2 = lengths_2[:min_length]
# new_lengths_3 = lengths_3[:min_length]

# # Create new folder paths
# NEW_DATA_PATH_1 = DATA_PATH_1 / 'processed'
# NEW_DATA_PATH_2 = DATA_PATH_2 / 'processed'
# NEW_DATA_PATH_3 = DATA_PATH_3 / 'processed'

# # Create directories if they do not exist
# NEW_DATA_PATH_1.mkdir(parents=True, exist_ok=True)
# NEW_DATA_PATH_2.mkdir(parents=True, exist_ok=True)
# NEW_DATA_PATH_3.mkdir(parents=True, exist_ok=True)

# # Save the new arrays in the new folders without 'new_' prefix
# np.save(NEW_DATA_PATH_1 / 'chunks.npy', new_chunks_1)
# np.save(NEW_DATA_PATH_2 / 'chunks.npy', new_chunks_2)
# np.save(NEW_DATA_PATH_3 / 'chunks.npy', new_chunks_3)

# np.save(NEW_DATA_PATH_1 / 'references.npy', new_refs_1)
# np.save(NEW_DATA_PATH_2 / 'references.npy', new_refs_2)
# np.save(NEW_DATA_PATH_3 / 'references.npy', new_refs_3)

# np.save(NEW_DATA_PATH_1 / 'reference_lengths.npy', new_lengths_1)
# np.save(NEW_DATA_PATH_2 / 'reference_lengths.npy', new_lengths_2)
# np.save(NEW_DATA_PATH_3 / 'reference_lengths.npy', new_lengths_3)

