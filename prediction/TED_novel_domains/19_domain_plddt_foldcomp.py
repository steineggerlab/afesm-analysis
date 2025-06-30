import sys

if len(sys.argv) != 4:
  print("")
  exit()

foldcomp_db = sys.argv[1]
domain_table = sys.argv[2]
output_table = sys.argv[3]

print("executed")

import pandas as pd
import os
from avg_bfactor import calculate_avg_bfactor_from_foldcomp, calculate_avg_bfactor_from_parser

f_domain = pd.read_csv(domain_table, delimiter="\t", header=None, names="entry_domain".split("_"))


import foldcomp
import io
from Bio.PDB import PDBParser, Selection
import io

def domain_plddt(structure, domain):
  # print(domain)
  regions = domain.split(",")
  slen = 0
  splddt = 0
  
  for i in range(0, len(regions), 3):
    try:
      s = int(regions[i])
      e = int(regions[i+1])
    except:
      print(structure, regions,)
      exit()
    slen += e - s + 1
    splddt += calculate_avg_bfactor_from_parser(structure, "A", s, e)  * ( e - s + 1)

  avg_plddt = round(splddt / slen, 2)
  
  return avg_plddt
    
db = foldcomp.open(foldcomp_db)

results = []

# i = 0

for (name, pdb) in db:
  # print(name)
  entry = name.split(".")[0]
  row = f_domain[ f_domain['entry'] == entry ]
  if len(row) == 0:
    continue
  parser = PDBParser(QUIET=True)
  pdb_io = io.StringIO(pdb)
  structure = parser.get_structure("esmfold_model", pdb_io)
  
  plddt = domain_plddt(structure, row['domain'].iloc[0])

  results.append({"entry": entry, "domain_plddt": plddt})

  # i += 1

  # if i == 10:
  #   break
print("foldcomp traversed")

plddt_df = pd.DataFrame(results)

# Merge the new DataFrame with f_domain on the "entry" key
f_domain = f_domain.merge(plddt_df, on="entry", how="right")


f_domain[['entry', 'domain_plddt']].to_csv(output_table, sep='\t', index=False)