"""
Description:
    This script generates a `partitions.json` file by scanning a specified source directory for `.pod5` files. It ensures that each `.pod5` filename is unique and partitions the files into groups where the total size of each partition does not exceed a user-defined limit in gigabytes. The resulting JSON file organizes the partitions with clear labels (e.g., `partition_1`, `partition_2`), facilitating organized processing for downstream tasks.

Key Features:
    - **File Discovery:** Recursively searches the source directory for `.pod5` files, ensuring no duplicate filenames exist.
    - **Partitioning Logic:** Groups files into partitions based on a specified size limit, preventing any partition from exceeding the defined threshold.
    - **Output Generation:** Saves the partitioned file groups into a structured `partitions.json` file with sequentially labeled partitions.
    - **Error Handling:** Alerts and exits if duplicate filenames are found or if any single file exceeds the partition size limit.

Usage:
    python partitions_creator.py <source_dir> <size_limit_gb> [--output_dir <output_directory>]

Arguments:
    source_dir      : Path to the directory containing `.pod5` files.
    size_limit_gb   : Maximum size per partition in gigabytes.
    --output_dir    : (Optional) Directory to save the `partitions.json` file. Defaults to the current working directory.
"""

import os
import argparse
import sys
import json

def get_all_pod5_files(source_dir):
    """
    Recursively gather all .pod5 files within the source directory and its subdirectories.
    Ensures that each filename is unique across all directories.

    Args:
        source_dir (str): Path to the source directory.

    Returns:
        dict: Dictionary mapping unique file paths to their sizes in bytes.

    Raises:
        SystemExit: If duplicate filenames are found.
    """
    pod5_files = {}
    seen_filenames = set()

    for dirpath, dirnames, filenames in os.walk(source_dir, followlinks=False):
        for f in filenames:
            if f.endswith(".pod5"):
                file_path = os.path.join(dirpath, f)
                try:
                    # Resolve the absolute path
                    abs_file_path = os.path.abspath(file_path)
                    
                    # Check for duplicate filenames
                    if f in seen_filenames:
                        print(f"[ERROR] Duplicate filename detected: '{f}' in '{abs_file_path}'")
                        sys.exit(1)
                    
                    # Add filename to the seen set
                    seen_filenames.add(f)
                    
                    # Get file size
                    file_size = os.path.getsize(abs_file_path)
                    
                    # Add to the dictionary
                    pod5_files[abs_file_path] = file_size

                except OSError as e:
                    print(f"[WARNING] Unable to access '{file_path}': {e}")

    return pod5_files

def partition_files(file_dict, size_limit_bytes):
    """
    Partition the dictionary of files into sub-dictionaries where the total size of each sub-dictionary does not exceed the size limit.

    Args:
        file_dict (dict): Dictionary mapping unique file paths to their sizes in bytes.
        size_limit_bytes (int): Maximum allowed size per partition in bytes.

    Returns:
        list of dict: List of partitioned dictionaries.
    """
    partitions = []
    current_partition = {}
    current_size = 0

    # Sort files by size in descending order
    sorted_files = sorted(file_dict.items(), key=lambda x: x[1], reverse=True)

    for file_path, file_size in sorted_files:
        if file_size > size_limit_bytes:
            print(f"[ERROR] File '{file_path}' exceeds the size limit of {convert_bytes_to_gb(size_limit_bytes):.2f} GB.")
            sys.exit(1)

        if current_size + file_size > size_limit_bytes:
            partitions.append(current_partition)
            current_partition = {file_path: file_size}
            current_size = file_size
        else:
            current_partition[file_path] = file_size
            current_size += file_size

    if current_partition:
        partitions.append(current_partition)

    print(f"[INFO] Total partitions created: {len(partitions)}")

    # Print the size of each partition in GB
    for idx, partition in enumerate(partitions, start=1):
        partition_size_bytes = sum(partition.values())
        partition_size_gb = convert_bytes_to_gb(partition_size_bytes)
        print(f"[INFO] Size of partition_{idx}: {partition_size_gb:.2f} GB")

    return partitions

def convert_bytes_to_gb(size_bytes):
    """
    Convert bytes to gigabytes.

    Args:
        size_bytes (int): Size in bytes.

    Returns:
        float: Size in gigabytes.
    """
    return size_bytes / (1024 ** 3)

def save_partitions(partitions, output_file):
    """
    Save all partitions into a single JSON file with keys like 'partition_1', 'partition_2', etc.

    Args:
        partitions (list of dict): List of partitioned dictionaries of files.
        output_file (str): Path to the output JSON file.
    """
    aggregated_partitions = {}
    for idx, partition in enumerate(partitions, start=1):
        partition_key = f"partition_{idx}"
        aggregated_partitions[partition_key] = partition

    try:
        with open(output_file, 'w') as f:
            json.dump(aggregated_partitions, f, indent=4)
        print(f"[INFO] Saved all partitions to '{output_file}'")
    except Exception as e:
        print(f"[ERROR] Failed to save partitions to '{output_file}': {e}")

def main():
    parser = argparse.ArgumentParser(description="List and partition .pod5 files based on size limit.")
    parser.add_argument("source_dir", type=str, help="Source directory containing .pod5 files.")
    parser.add_argument("size_limit_gb", type=float, help="Size limit for each partition in GB.")
    parser.add_argument("--output_dir", type=str, default=None, help="Directory to save the partition JSON file. If not specified, defaults to the current working directory from which the script is executed.")

    args = parser.parse_args()

    source_dir = os.path.abspath(args.source_dir)
    size_limit_gb = args.size_limit_gb
    size_limit_bytes = size_limit_gb * (1024 ** 3)
    output_dir = os.path.abspath(args.output_dir) if args.output_dir else os.getcwd()

    # Define the output JSON file path
    output_file = os.path.join(output_dir, "partitions.json")

    print("=============================================")
    print("Starting File Listing and Partitioning")
    print(f"Source Directory: {source_dir}")
    print(f"Size Limit per Partition: {size_limit_gb} GB")
    print("=============================================")

    # Gather all .pod5 files with uniqueness checks
    pod5_files = get_all_pod5_files(source_dir)
    total_files = len(pod5_files)
    total_size = sum(pod5_files.values())
    total_size_gb = convert_bytes_to_gb(total_size)

    print(f"[INFO] Total .pod5 files found: {total_files}")
    print(f"[INFO] Total size of .pod5 files: {total_size_gb:.2f} GB")

    if total_files == 0:
        print("[WARNING] No .pod5 files found. Exiting.")
        sys.exit(0)

    # Partition files
    partitions = partition_files(pod5_files, size_limit_bytes)

    # Save all partitions into a single JSON file
    save_partitions(partitions, output_file)

    print("=============================================")
    print("File Listing and Partitioning Completed Successfully.")
    print("=============================================")

if __name__ == "__main__":
    main()

