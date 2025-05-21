#!/bin/python3

import pandas as pd
import re

output_rows = []

with open("cath-names.txt", "r") as infile:
    for line in infile:
        line = line.strip()
        if not line or line.startswith("#"):
            continue  # skip header/comments
        match = re.match(r'^(\S+)\s+(\S+)\s*:(.*)$', line)
        if match:
            col1 = match.group(1)
            col2 = match.group(2)
            col3 = match.group(3).replace(":", "")  # remove colon from field 3
            output_rows.append([col1, col2, col3])

# Write TSV output
df = pd.DataFrame(output_rows)
df.to_csv("cath-names.tsv", sep="\t", header=False, index=False, quoting=3)