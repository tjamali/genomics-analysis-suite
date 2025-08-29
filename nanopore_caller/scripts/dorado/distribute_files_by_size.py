import os
import shutil
import argparse
import sys

def calculate_dir_size_bytes(dir_path):
    """
    Calculate the total size of the directory in bytes.

    Args:
        dir_path (str): Path to the directory.

    Returns:
        int: Size of the directory in bytes.
    """
    total_size = 0
    for dirpath, dirnames, filenames in os.walk(dir_path):
        for f in filenames:
            fp = os.path.join(dirpath, f)
            # Skip if it's a symbolic link
            if not os.path.islink(fp):
                try:
                    total_size += os.path.getsize(fp)
                except OSError as e:
                    print(f"[WARNING] Unable to access {fp}: {e}")
    return total_size

def convert_bytes_to_gb(size_bytes):
    """
    Convert bytes to gigabytes.

    Args:
        size_bytes (int): Size in bytes.

    Returns:
        float: Size in gigabytes.
    """
    return size_bytes / (1024 ** 3)

def check_all_subfolders_within_limit(source_dir, size_limit_bytes):
    """
    Check if all immediate subdirectories within source_dir are within the size limit.

    Args:
        source_dir (str): Path to the main directory.
        size_limit_bytes (int): Maximum allowed size per subfolder in bytes.

    Returns:
        bool: True if all subfolders are within the limit, False otherwise.
    """
    all_within_limit = True
    subfolders = [os.path.join(source_dir, d) for d in os.listdir(source_dir)
                  if os.path.isdir(os.path.join(source_dir, d))]

    for subfolder in subfolders:
        sub_size = calculate_dir_size_bytes(subfolder)
        sub_size_gb = convert_bytes_to_gb(sub_size)
        print(f"[INFO] Size of {os.path.basename(subfolder)}: {sub_size_gb:.2f} GB")
        if sub_size > size_limit_bytes:
            print(f"[WARNING] Subfolder {os.path.basename(subfolder)} exceeds the size limit of {convert_bytes_to_gb(size_limit_bytes):.2f} GB.")
            all_within_limit = False
    return all_within_limit

def check_no_nested_subfolders(source_dir):
    """
    Check that there are no nested subfolders within any immediate subdirectory of source_dir.

    Args:
        source_dir (str): Path to the main directory.

    Raises:
        SystemExit: If any nested subfolders are detected.
    """
    subfolders = [d for d in os.listdir(source_dir) if os.path.isdir(os.path.join(source_dir, d))]

    for subfolder in subfolders:
        subfolder_path = os.path.join(source_dir, subfolder)
        # Check if any subdirectory exists within this subfolder
        nested_subfolders = [d for d in os.listdir(subfolder_path) if os.path.isdir(os.path.join(subfolder_path, d))]
        if nested_subfolders:
            print(f"[ERROR] Nested subfolders detected in '{subfolder_path}'.")
            print("[ERROR] Acceptable structure: pod5 files or subfolders containing only pod5 files without nested subfolders.")
            sys.exit(1)  # Exit with a non-zero status to indicate an error

def flatten_directory(source_dir):
    """
    Flatten the directory by moving all files from any subdirectories back to source_dir.
    Removes empty subdirectories after moving the files.

    Args:
        source_dir (str): Path to the main directory.
    """
    print(f"[INFO] Flattening subdirectories in {source_dir}...")
    for dirpath, dirnames, filenames in os.walk(source_dir, topdown=False):
        # Skip the main directory
        if dirpath == source_dir:
            continue
        for file in filenames:
            src_file = os.path.join(dirpath, file)
            dest_file = os.path.join(source_dir, file)
            try:
                shutil.move(src_file, dest_file)
                # Removed the [DEBUG] moved file message
            except Exception as e:
                print(f"[ERROR] Failed to move {src_file} to {dest_file}: {e}")
        # Attempt to remove the empty directory
        try:
            os.rmdir(dirpath)
        except OSError:
            print(f"[WARNING] Directory {dirpath} is not empty or cannot be removed.")
    print("[INFO] Flattening of subdirectories completed.")

def distribute_files(source_dir, target_dir, size_limit_bytes):
    """
    Distribute files from the source directory into subfolders in the target directory 
    based on a size limit for each subfolder.

    Args:
        source_dir (str): Path to the source directory containing files to distribute.
        target_dir (str): Path to the target directory where subfolders will be created.
        size_limit_bytes (int): Size limit for each subfolder in bytes.
    """
    print("[INFO] Starting file distribution...")

    # Gather all files in the source directory (flattened)
    all_files = [os.path.join(source_dir, f) for f in os.listdir(source_dir)
                 if os.path.isfile(os.path.join(source_dir, f))]

    # Sort files by size in descending order
    try:
        all_files.sort(key=lambda x: os.path.getsize(x), reverse=True)
    except OSError as e:
        print(f"[ERROR] Failed to sort files by size: {e}")
        return

    subfolder_index = 0
    current_subfolder_size = 0
    current_subfolder_path = os.path.join(target_dir, f"subfolder_{subfolder_index}")
    try:
        os.makedirs(current_subfolder_path, exist_ok=True)
        print(f"[INFO] Created subfolder {current_subfolder_path}")
    except Exception as e:
        print(f"[ERROR] Failed to create subfolder {current_subfolder_path}: {e}")
        return

    for file_path in all_files:
        try:
            file_size = os.path.getsize(file_path)
        except OSError as e:
            print(f"[WARNING] Unable to access {file_path}: {e}")
            continue

        if current_subfolder_size + file_size > size_limit_bytes:
            subfolder_index += 1
            current_subfolder_path = os.path.join(target_dir, f"subfolder_{subfolder_index}")
            try:
                os.makedirs(current_subfolder_path, exist_ok=True)
                print(f"[INFO] Created subfolder {current_subfolder_path}")
            except Exception as e:
                print(f"[ERROR] Failed to create subfolder {current_subfolder_path}: {e}")
                continue
            current_subfolder_size = 0

        try:
            shutil.move(file_path, current_subfolder_path)
            # Removed the [DEBUG] moved file message
            current_subfolder_size += file_size
        except Exception as e:
            print(f"[ERROR] Failed to move {file_path} to {current_subfolder_path}: {e}")

    print("[INFO] File distribution completed successfully.")

def remove_empty_subfolders(source_dir):
    """
    Remove any empty subfolders within the source directory.

    Args:
        source_dir (str): Path to the main directory.
    """
    print(f"[INFO] Removing any empty subfolders in {source_dir}...")
    removed_any = False
    for dirpath, dirnames, filenames in os.walk(source_dir, topdown=False):
        for dirname in dirnames:
            subdir_path = os.path.join(dirpath, dirname)
            try:
                os.rmdir(subdir_path)
                print(f"[INFO] Removed empty directory {subdir_path}")
                removed_any = True
            except OSError:
                # Directory not empty or cannot be removed
                continue
    if not removed_any:
        print("[INFO] No empty subfolders found to remove.")
    else:
        print("[INFO] Removal of empty subfolders completed.")

def main():
    parser = argparse.ArgumentParser(description="Distribute files into subfolders based on size limit.")
    parser.add_argument("source_dir", type=str, help="Source directory containing files to distribute.")
    parser.add_argument("target_dir", type=str, help="Target directory to create subfolders in.")
    parser.add_argument("size_limit", type=float, help="Size limit for each subfolder in GB.")

    args = parser.parse_args()

    source_dir = os.path.abspath(args.source_dir)
    target_dir = os.path.abspath(args.target_dir)
    size_limit_gb = args.size_limit

    size_limit_bytes = size_limit_gb * (1024 ** 3)

    print("=============================================")
    print("Checking if file distribution is required")
    print(f"Directory: {source_dir}")
    print("=============================================")

    # Calculate the size of source_dir
    dir_size_bytes = calculate_dir_size_bytes(source_dir)
    dir_size_gb = convert_bytes_to_gb(dir_size_bytes)
    print(f"[INFO] Total size of source directory: {dir_size_gb:.2f} GB")

    # Initialize a flag to determine whether to run distribution
    run_distribution = False

    if dir_size_bytes > size_limit_bytes:
        print(f"[INFO] Directory size exceeds the size limit of {size_limit_gb} GB.")

        # Check if there are any subdirectories
        subfolders = [d for d in os.listdir(source_dir) if os.path.isdir(os.path.join(source_dir, d))]

        if subfolders:
            # Check for nested subfolders before verifying sizes
            print("[INFO] Checking for nested subfolders...")
            check_no_nested_subfolders(source_dir)

            print("[INFO] Existing subdirectories detected. Verifying their sizes...")

            # Check if all subdirectories are within the size limit
            if check_all_subfolders_within_limit(source_dir, size_limit_bytes):
                print(f"[INFO] All existing subdirectories are within the size limit of {size_limit_gb} GB.")

                # Remove any empty subfolders
                remove_empty_subfolders(source_dir)

                print("[INFO] Skipping file distribution.")
            else:
                print("[INFO] Some subdirectories exceed the size limit. Flattening and re-distributing files.")
                flatten_directory(source_dir)
                run_distribution = True
        else:
            print("[INFO] No existing subdirectories found. Initiating file distribution.")
            run_distribution = True

        if run_distribution:
            print("=============================================")
            print(f"Starting file distribution in {source_dir}")
            print(f"Size Limit per Subfolder: {size_limit_gb} GB")
            print("=============================================")

            # Execute the distribution
            distribute_files(source_dir, target_dir, size_limit_bytes)

            # Remove any empty subfolders that might exist after distribution
            remove_empty_subfolders(source_dir)

    else:
        print(f"[INFO] Directory size is within the size limit of {size_limit_gb} GB. Skipping file distribution.")

if __name__ == "__main__":
    main()

