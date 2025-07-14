#!/bin/bash

# Directory containing the batch files
BATCH_DIR="msa_batch00_2000/"

# Loop through each batch file
for batch_file in "$BATCH_DIR"/batch00_r02_msa_filenames_batch*; do
    # Extract the batch number from the filename
    batch_name=$(basename "$batch_file")
    
    # Create a corresponding directory
    target_dir="${BATCH_DIR}/${batch_name}_dir"
    mkdir -p "$target_dir"
    
    # Read the filenames from the batch file and move them to the directory
    while read -r file; do
        if [ -f "$file" ]; then
            mv "$file" "$target_dir/"
        else
            echo "Warning: File $file not found, skipping."
        fi
    done < "$batch_file"
done

echo "Processing completed."
