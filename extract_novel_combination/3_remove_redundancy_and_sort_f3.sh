#!/bin/bash

input="$1"
output="$2"

awk -F"\t" -v OFS="\t" '
{
    # Check if the second field is empty
    if ($3 != "") {
        # Split the $3 field by ";" into an array
        n = split($3, array, ";")

        # Use an associative array to remove redundancy
        delete unique_array
        for (i = 1; i <= n; i++) {
            # Ensure non-empty elements are added
            if (array[i] != "") {
                unique_array[array[i]] = 1
            }
        }

        # Collect the unique elements into a sorted array
        sorted_string = ""
        PROCINFO["sorted_in"] = "@ind_str_asc"
        for (element in unique_array) {
            sorted_string = sorted_string (sorted_string ? ";" : "") element
        }

        # Print the output with the sorted array
        print $1, $2, sorted_string
    } else {
        # If the second field is empty, just print the original line
        print $0
    }
}' "$input" > "$output"


 
