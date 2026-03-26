#!/bin/bash

# Assign input arguments to variables
input1="$1"
input2="$2"
output="$3"

# Use awk to filter lines based on the third column
awk -F'\t' -v OFS='\t' '
# Process the first input file
NR==FNR {
    data[$3] = 1   # Store the value of the third column in an associative array
    next           # Move to the next line in the first file
}
# Process the second input file
{
    if (!($3 in data)) {   # If the value of the third column is not in the associative array
        print $0          # Print the line
    }
}
' "$input1" "$input2" > "$output"   # Specify the input files and output file



# ../data_AF/AF_result_concat_multi_lv3_nonRedunSortedComb_coparis_FINAL.tsv 
# ../data/temp_data/temp_data_3_result-nonRedunSortedComb_copairs.tsv