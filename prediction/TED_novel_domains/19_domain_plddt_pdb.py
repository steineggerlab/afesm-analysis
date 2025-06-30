import sys

if len(sys.argv) != 4:
  print("")
  exit()

pdb_dir = sys.argv[1]
domain_table = sys.argv[2]
output_table = sys.argv[3]

import pandas as pd
import os
from avg_bfactor import calculate_avg_bfactor

f_domain = pd.read_csv(domain_table, delimiter="\t", header=None, names="entry_domain".split("_"))
# print(f_domain.head())
def domain_plddt(x):
  regions = x['domain'].split(",")
  slen = 0
  splddt = 0
  
  for i in range(0, len(regions), 3):
    s = int(regions[i])
    e = int(regions[i+1])
    slen += e - s + 1
    splddt += calculate_avg_bfactor(pdb_dir + "/" + x['entry'] + ".pdb", "A", s, e)  * ( e - s + 1)

  avg_plddt = round(splddt / slen, 2)

  return avg_plddt

# f_domain = f_domain.head()
f_domain['domain_plddt'] = f_domain.apply(domain_plddt, axis=1)

f_domain[['entry', 'domain_plddt']].to_csv(output_table, sep='\t', index=False)