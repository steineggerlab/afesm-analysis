import os
import sys

MIN_DOM_SIZE = 25
MIN_FRAGMENT_SIZE = 5

input_file = sys.argv[1]
# name = sys.argv[2]

bn, ext = os.path.splitext(input_file)
out_full = bn + '_filtered.tsv'
out_domain = bn + '_domains_filtered.tsv'

full = []
domains = []

with open(input_file, 'r') as f:
    for i, line in enumerate(f.readlines()):
        line = line.rstrip('\n')
        
        target, md5, nres, ndom, chopping, score = line.split()
        
        new_nres = 0
        new_chopping = []
        if chopping != 'NULL' and chopping != 'NO_SS':
            for nd, d in enumerate(chopping.split(',')):
                dom_nres = 0
                new_dd_chopping = []
                
                for dd in d.split('_'):
                    rng = dd.split('-')
                    if len(rng) == 2:
                        start, end = rng
                        seg_nres = int(end) - int(start) + 1
                        
                        if seg_nres >= MIN_FRAGMENT_SIZE:
                            dom_nres += seg_nres
                            new_dd_chopping.append('-'.join([start, end]))
                
                if dom_nres >= MIN_DOM_SIZE:
                    new_nres += dom_nres
                    dom_chopping = '_'.join(new_dd_chopping)
                    new_chopping.append(dom_chopping)
                    
                    # Also save a domain-level summary
                    # dom_name = target + '_' + str(nd+1).zfill(2)
                    # domains.append("{}\t{}\t{}\t{}\t{}\t{}".format(dom_name, md5, dom_nres, 1.000, 1.000, dom_chopping))
                    
            new_ndom = len(new_chopping)
            new_chopping = ','.join(new_chopping)
            
            if len(new_chopping) == 0:
                new_chopping = 'NULL'
                
        else:
            new_ndom = ndom
            new_chopping = chopping

        full.append("{}\t{}\t{}\t{}\t{}\t{}".format(target, md5, nres, new_ndom, new_chopping, score))   
        
        
# Save the new filtered chopping in full-chain format
with open(out_full, 'w') as fn:
    for line in full:
        fn.write(line + '\n')     
        
# with open(out_domain, 'w') as fn:
#     for line in domains:
#         fn.write(line + '\n')     
        
