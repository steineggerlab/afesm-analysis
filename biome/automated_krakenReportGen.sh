#!/bin/bash

# Check if an argument is provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <file2>"
    exit 1
fi

# Assigning file names
file1="id_lineage_correct2.dmp"
file2="$1"
output="${file2%.tsv}Kraken.tsv"  # Extracts the base name of file2 and appends 'Kraken.tsv'

# Create a temporary directory
mkdir -p temp

# AWK script for processing
awk -F"\t" -v OFS='\t' '
    # Load file1 data into an associative array
    FNR == NR {
        data[$3] = $1
        next
    }
    # Process file2 and print out
    {
        path = $1
        # Check if the path is in our associative array
        if (path ~ /root/ && path in data) {
            print data[path]
        } 
    }
' "$file1" "$file2" > temp/code.tsv

# Perl script for generating Kraken report file
perl y_gen_krakenreport4.pl temp/code.tsv > temp/Kraken_temp.tsv

# Second AWK script for formatting
awk '{
    gsub(/\tS\t/, "\tspecies\t");
    gsub(/\tG\t/, "\tgenus\t");
    gsub(/\tF\t/, "\tfamily\t");
    gsub(/\tO\t/, "\torder\t");
    gsub(/\tC\t/, "\tclass\t");
    gsub(/\tP\t/, "\tphylum\t");
    gsub(/\tK\t/, "\tkingdom\t");
    gsub(/\tD\t/, "\tsuperkingdom\t");
    gsub(/\tU\t/, "\tno rank\t");
    gsub(/-\t1\troot/, "no rank\t1\troot");  # Added substitution
    print
}' temp/Kraken_temp.tsv > "$output"

echo "Report generated: $output"
