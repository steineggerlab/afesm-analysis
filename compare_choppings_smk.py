import os
# import glob
import argparse
# import subprocess
# import shutil
# import imageio
# import math

import numpy as np
# import matplotlib.pyplot as plt

from utils.score_utils import domstr_to_ranges
from utils.domain_consensus import calculate_domain_consensus
# from utils.pdb_utils import open_pdb, select_from_mol

# Author:
# A Lau - 2023-06-07
# S Kandathil - 2024-07-02 NO PLOTS

# Given an index file and some chopping files, generates an image for each set of targets listed in the 
# index file, based on choppings for each method. Can handle a variable number of chopping files. 

# This DOES NOT convert e.g. [merizo.out, chainsaw.out, unidoc.out, crh.out] -> png
# If your inputs are pdbs with domain ids formatted onto the occ column, use compare_choppings_pdb.py instead.

# Example:
# python compare_choppings.py -d ../../datasets/data/human_200_afdb -o ~/comparison_4-way_consensus_fix -c ../../datasets/data/human_200_afdb_domains/{merizo,chainsaw,unidoc,crh.fix}.out

scriptdir = os.path.dirname(os.path.realpath(__file__))
px_scale = 2000

np_color_list = [
    (210, 210, 210), (89, 174, 58), (219, 34, 0), (138, 198, 202),
    (164, 89, 162), (17, 39, 141), (229, 119, 0), (164, 119, 118),
    (180, 165, 3), (49, 140, 47), (230, 141, 139), (25, 141, 141),
    (230, 217, 0), (184, 133, 182), (81, 57, 150), (0, 0, 0),
]

consensus_color = [
    (89, 174, 58), (229, 119, 0), (219, 34, 0)
]

def read_chopping(file):
    with open(file, 'r') as f:
        contents = []
        targets = []
        for line in f:
            if line[:5] != 'Done.':
                line = line.rstrip('\n').split('\t')
                
                assert len(line) == 6, f"Expected 6 fields in chopping file {file} in format: 'target,md5,nres,ndom,chopping,score'"
                
                targets.append(line[0])
                contents.append(line)
        
    return targets, np.array(contents)

def main():
    # Read the config file
    parser = argparse.ArgumentParser()
    # parser.add_argument("-i", "--index", type=str, required=False, default=os.path.join(scriptdir, '../../datasets/index/human_200.index'))
    parser.add_argument("-c", "--choppings", type=str, nargs="+", required=True, help="Pass a list of files containing domain choppings.")
    # parser.add_argument("-d", "--model_dir", type=str, required=True, help="Give directory of where the original pdbs are.")
    parser.add_argument("-o", "--output_dir", type=str, required=True, help="Give directory to save consensus tsv to.", default=os.environ['PWD'])
    # parser.add_argument("-s", "--size", type=float, required=False, default=5, help="Image size in cm for each model.")
    # parser.add_argument("-lw", "--linewidth", type=float, required=False, default=10, help="Linewidth for plots.")
    args = parser.parse_args()
    
    if not os.path.exists(args.output_dir):
        os.mkdir(args.output_dir)
    
    # Open the chopping files
    targets = []
    chopping_files = {}
    for f in args.choppings: 
        bn, _ = os.path.splitext(os.path.basename(f))
        chopping_targets, chopping_files[bn] = read_chopping(f)
        targets.extend(chopping_targets)
        
    # Get unique list of targets from all chopping files
    unique_targets = list(set(targets))
    
    for target in unique_targets:
        # outname = os.path.join(args.output_dir, target + '.png')
        
        dom_method = []
        method_choppings = []
        for k, v in chopping_files.items():
            match = v[v[:,0] == target]
            # Check that only one match can be made
            assert len(match) > 0, f"Entry not found for {target} in chopping file {k}"
            assert len(match) < 2, f"Multiple matches for target {target} in chopping file {k}."
            
            # Format domain string into a pymol command
            target, md5, nres, ndom, chopping, score = match[0]
            nres, ndom, score = int(nres), int(ndom), float(score)

            if chopping not in ['0','NULL','NO_SS']:
                dom_method.append(domstr_to_ranges(chopping))
                method_choppings.append(chopping)
            else:
                dom_method.append([[0, 1, nres-1]])

        # Calculate the consensus between the multiple assignments:
        consensus, consensus_domstr, consensus_counts = calculate_domain_consensus(method_choppings, nres, consensus_levels=[3,2,1])
        high, medium, low = consensus_domstr
        nhigh, nmed, nlow = consensus_counts
        
        with open(os.path.join(args.output_dir, 'consensus_chopping.out'), 'a+') as f:
            f.write("{}\t{}\t{:.0f}\t{}\t{}\t{}\t{}\t{}\t{}\n".format(
                target, md5, nres, nhigh, nmed, nlow, high, medium, low,
            ))

        continue




        # # Stitch the individual pngs together, save as a set, and delete the original
        # n_models = len(fn_str)   
        fig_width = args.size
        fig_height = args.size
        lw = args.linewidth
        
        # _, axs = plt.subplots(nrows=1, ncols=n_models, figsize=(fig_width, fig_height))
        # axs = axs.flatten()
        
        # for i, (method, png_path) in enumerate(png_paths): 
        #     if os.path.exists(png_path):
        #         axs[i].imshow(plt.imread(png_path))
        #         axs[i].set(title=f"{target} ({method})")
        #         axs[i].axis('off')
            
        # png_path_pdb = outname[:-4] + '_pdb.png'
        # plt.savefig(png_path_pdb, bbox_inches='tight')
        # plt.close()
        
        # Generate a sequence overlap version
        f = plt.subplots(2, 3, 
            gridspec_kw={'width_ratios': [1, 3, 1], 'height_ratios': [1, 2]},
            figsize=(fig_width, fig_height)
        )

        ticklabels = []
        for i, m in enumerate(dom_method):
            y = i + 1
            f.plot([1, nres], [y, y], linewidth=lw, color=(0.82, 0.82, 0.82))
            # ticklabels.append(method)

            for (idx, start, end) in m:
                rgb = np_color_list[idx % len(np_color_list)]
                color = np.array(rgb).astype(np.float16) / 255.
                f.plot([start+1, end+1], [y, y], linewidth=lw, color=color)

        print(consensus)
        
        # Plot consensus
        # y = n_models + 2
        # ticklabels.extend(['','low','medium','high'])
        # # ax4.plot([1, nres], [y, y], linewidth=lw, color=(0.82, 0.82, 0.82))
        
        # for i, (cons, col) in enumerate(zip(reversed(consensus), reversed(consensus_color))):
        #     ax4.plot([1, nres], [y+i, y+i], linewidth=lw, color=(0.82, 0.82, 0.82))
        #     col = np.array(col) / 255.
            
        #     if len(cons) > 0:
        #         for (_, start, end) in cons:
        #             print(i, start, end, col)
        #             ax4.plot([start+1, end+1], [y+i, y+i], linewidth=lw, color='black')
        #             ax4.plot([start+1, end+1], [y+i, y+i], linewidth=lw-2.5, color=col)
                    
        # edge = nres * 0.05
        # ax4.set_xlim([-edge, nres + edge])
        # ax4.set_ylim([0, len(dom_method)+5])
        # ax4.set_yticks(np.arange(0, len(ticklabels))+1)
        # ax4.set_yticklabels(ticklabels)
        # ax4.yaxis.set_tick_params(labelsize=12)
        # ax4.xaxis.set_tick_params(labelsize=12)
        # ax4.set_xlabel('Residues', fontsize=12)
        # ax4.spines['top'].set_visible(False)
        # ax4.spines['left'].set_visible(False)
        # ax4.spines['right'].set_visible(False)
        # ax4.set_facecolor('whitesmoke')
                   
        # plt.subplots_adjust(hspace=0.05)
        
        png_path_seq = outname[:-4] + '_seq.png'
        plt.savefig(png_path_seq, bbox_inches='tight')
        plt.close()

        # # if both the pdb and seq image has been generated, then stitch together
        # if os.path.exists(png_path_pdb) and os.path.exists(png_path_seq):
        #     png_seq = imageio.imread(png_path_seq)

        #     im_widths = [png_pdb.shape[1], png_seq.shape[1]]
        #     if im_widths[0] != im_widths[1]:
        #         w_max, w_min = np.max(im_widths), np.min(im_widths)
        #         diff = w_max - w_min
        #         n_pad_right = diff // 2
                
        #         if (diff % 2) != 0:
        #             n_pad_left = n_pad_right +1
        #         else:
        #             n_pad_left = n_pad_right

        #         pad = ((0, 0), (n_pad_left, n_pad_right), (0, 0))
        #         if png_pdb.shape[1] < png_seq.shape[1]:
        #             png_pdb = np.pad(png_pdb, pad, 'constant', constant_values=(255,255))
        #         else:
        #             png_seq = np.pad(png_seq, pad, 'constant', constant_values=(255,255))
            
        #     png_combined = np.concatenate((png_pdb, png_seq), axis=0)
        #     imageio.imwrite(outname, png_combined)
        
        # # Cleaning
        # if os.path.exists(png_path_pdb):
        #     os.remove(png_path_pdb)
            
        # if os.path.exists(png_path_seq):
        #     os.remove(png_path_seq)


if __name__ == "__main__":
    main()
