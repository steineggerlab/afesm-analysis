import os
import argparse
import pandas as pd
import numpy as np

from utils.score_utils import (
    domstr_to_assignment_by_resi,
    assignment_to_domstr,
    read_chopping
)

from utils.pdb_utils import (
    open_pdb,
    write_pdb,
    add_domains_to_pdb,
    select_from_mol
)

# Authors: 
# A Lau - 2023-05-30
# A Lau - 2023-08-08 - this uses the resi array to make the assignment now

# Given a chopping file and a dir of PDBs, generates a pdb with the chopping formatted into the 
# PDB occupancy column.
# Note: Don't use b-factor column to preserve AF2 plDDTs. 

# Usage: python chopping_to_pdb.py -i <chopping.txt> -d </path/to/models> -o </path/to/output/dir/> -l <file suffix, e.g. _c2m.pdb>

def main():
    # Read the config file
    parser = argparse.ArgumentParser()
    parser.add_argument("-i", "--input", type=str, required=True)
    parser.add_argument("-d", "--model_dir", type=str, required=True)
    parser.add_argument("-o", "--output_dir", type=str, required=True)
    parser.add_argument("-il", "--input_model_label", type=str, required=False, default='.pdb')
    parser.add_argument("-ol", "--output_model_label", type=str, required=False, default='.pdb')
    parser.add_argument("-m", "--inherit_from", type=str, required=False, default=None)
    parser.add_argument("-sd", "--save_domains", action='store_true', required=False, default=False)
    parser.add_argument("--skip_header", action='store_true', required=False, default=False)
    args = parser.parse_args()
    
    # Read assignment files
    headers = ['target','md5','nres','ndom','chopping','score']
    targets = read_chopping(args.input, headers, args.skip_header)
    
    if not os.path.exists(args.output_dir):
        os.mkdir(args.output_dir)
        
    if args.inherit_from is not None:
        # if a second chopping file is provided, e.g. Merizo, inherit NDR assignments from
        # the provided file.
        inherit = read_chopping(args.inherit_from, headers)
        new_table = [] # New table for storing the changed chopping

    for i, row in targets.iterrows():
        # try:
        comments = []
        target, md5, nres, chopping = row[['target','md5','nres','chopping']]
        nres = int(nres)

        target_pdb = os.path.join(args.model_dir, target + args.input_model_label)
        out_fn = os.path.join(args.output_dir, target + args.output_model_label)
        
        new_fn, new_ext = os.path.splitext(out_fn)
        domain_fn = new_fn + ".domains"
        
        if os.path.exists(target_pdb):
            if isinstance(chopping, str):
                pdb = open_pdb(target_pdb)
                pdb_resi = select_from_mol(pdb, 'n', ['CA'])['resi']
                
                # Format the domain string into an assignment array, e.g. [0,0,1,1,1,2,2,2,0,0]
                dom_assign = domstr_to_assignment_by_resi(chopping, pdb_resi).numpy()
                
                # if args.inherit_from is not None:
                #     inh_row = inherit[inherit['target'].str.match(target)]
                #     inh_md5, inh_chopping = inh_row['md5'].item(), inh_row['chopping'].item()
                    
                #     inh_assign = domstr_to_assignment(inh_chopping, nres).numpy()

                #     assert inh_md5 == md5, f"MD5 of the two files do not match for target {target}"

                #     inh_assign = domstr_to_assignment(inh_chopping, nres).numpy()
                #     dom_assign[inh_assign == 0] = 0
                #     comments.append('NDRs masked using assignments from ' + args.inherit_from)
                    
                # Transfer the domain assignments onto the pdb structure
                pdb_dom = add_domains_to_pdb(pdb, pdb_resi, dom_assign)

                # if args.inherit_from is not None:
                
                #     # Get the residue numbers after adding to PDB
                #     pdb_resi = select_from_mol(pdb_dom, 'n', ['CA'])['resi']
                    
                #     # Generate the new domain string and replace the original
                #     new_dom_str, ndom = assignment_to_domstr(dom_assign, pdb_resi)
                #     row['chopping'] = new_dom_str
                #     row['ndom'] = ndom
                    
                #     new_table.append(row.to_frame().T)

                # Write pdb to disk
                comments.extend(['Model generated using chopping_to_pdb.py', 'MD5 ' + md5])
                
                if args.save_domains:
                    unique_domains = [x for x in set(pdb_dom['occ']) if x != 0.0]
                    for n, d in enumerate(unique_domains):
                        if d != 0.0:
                            domain_pdb = pdb_dom[pdb_dom['occ'] == d]
                            domain_name = new_fn + f'_{str(n+1).zfill(2)}'
                            domain_path = domain_name + new_ext
                            
                            domain_ca = select_from_mol(domain_pdb, 'n', ['CA'])
                            bfactors = domain_ca['b'] # Get CA first then bfactors
                            mean_bfactor = np.mean(bfactors)
                            domain_nres = len(domain_ca)

                            dom_conf = 1.000 # Dummy for UniDoc
                            dom_str = assignment_to_domstr(domain_ca['occ'], domain_ca['resi'])[0]

                            with open(domain_fn, 'a+') as f:
                                f.write("{}\t{}\t{}\t{:.3f}\t{:.3f}\t{}\n".format(
                                    os.path.basename(domain_name), md5, domain_nres, dom_conf, mean_bfactor, dom_str
                                ))
                            
                            write_pdb(domain_pdb, domain_path, comments)
                else:
                    write_pdb(pdb_dom, out_fn, comments)
            
        # if i == 5: # test
        #     break
            
    if args.inherit_from is not None:
        new_table = pd.concat(new_table, axis=0, ignore_index=True)
        
        new_name, _ = os.path.splitext(args.input)
        new_table.to_csv(new_name + '_inherit.out', sep='\t', header=False, index=False)
            
    

if __name__ == "__main__":
    main()
