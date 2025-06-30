import sys
if len(sys.argv) < 9:
    print(f"{sys.argv[0]} <fasta file> <output dir> <start index> <end index> <batch size> <chunk size> <min_len> <max_len>")
    exit()

import re
from Bio import SeqIO
import os

fasta = sys.argv[1]
output_dir = sys.argv[2]
start_i = int(sys.argv[3])
end_i = int(sys.argv[4])
batch_size = int(sys.argv[5])
chunk_size = int(sys.argv[6])
min_len = int(sys.argv[7])
max_len = int(sys.argv[8])

sequences = []
ids = []
for seq_record in SeqIO.parse(fasta, "fasta"):
    ids.append(re.sub("\.cif.*", "", seq_record.id))
    sequences.append(str(seq_record.seq))


import pandas as pd

df = pd.DataFrame({'Entry': ids, 'Sequence': sequences})

if end_i > len(df):
    print(f"end index exceeds the size of the database {end_i}, {len(df)}")
    exit()

from transformers import AutoTokenizer, EsmForProteinFolding

tokenizer = AutoTokenizer.from_pretrained("facebook/esmfold_v1")
model = EsmForProteinFolding.from_pretrained("facebook/esmfold_v1", low_cpu_mem_usage=True)

model = model.cuda()


# Uncomment to switch the stem to float16
model.esm = model.esm.half()

import torch

torch.backends.cuda.matmul.allow_tf32 = True

# Uncomment this line if your GPU memory is 16GB or less, or if you're folding longer (over 600 or so) sequences
model.trunk.set_chunk_size(chunk_size)

from transformers.models.esm.openfold_utils.protein import to_pdb, Protein as OFProtein
from transformers.models.esm.openfold_utils.feats import atom14_to_atom37

def convert_outputs_to_pdb(outputs):
    final_atom_positions = atom14_to_atom37(outputs["positions"][-1], outputs)
    outputs = {k: v.to("cpu").numpy() for k, v in outputs.items()}
    final_atom_positions = final_atom_positions.cpu().numpy()
    final_atom_mask = outputs["atom37_atom_exists"]
    pdbs = []
    for i in range(outputs["aatype"].shape[0]):
        aa = outputs["aatype"][i]
        pred_pos = final_atom_positions[i]
        mask = final_atom_mask[i]
        resid = outputs["residue_index"][i] + 1
        pred = OFProtein(
            aatype=aa,
            atom_positions=pred_pos,
            atom_mask=mask,
            residue_index=resid,
            b_factors=outputs["plddt"][i],
            chain_index=outputs["chain_index"][i] if "chain_index" in outputs else None,
        )
        pdbs.append(to_pdb(pred))
    return pdbs

print("#sequences:", len(df.Sequence.tolist()))
df['length'] = df['Sequence'].apply(lambda x: len(x))
df = df.head(end_i).tail(end_i-start_i)
print(f"#index range : {start_i}~{end_i}")
df = df[ (df['length'] >= min_len) & (df['length'] <= max_len) ]
print("Selected #sequences:", len(df.Sequence.tolist()))

n = 0 
for i in range(start_i, len(df), batch_size):
    print(f"Step {n}: {i}~{i+batch_size-1}")
    n+=1
    print(df[i:i+batch_size])
    print(f"Sum length: {df[i:i+batch_size]['length'].sum()}")

    ecoli_tokenized = tokenizer(df[i:i+batch_size].Sequence.tolist(), padding=False, add_special_tokens=False)['input_ids']

    from tqdm import tqdm

    outputs = []

    with torch.no_grad():
        for input_ids in tqdm(ecoli_tokenized):
            input_ids = torch.tensor(input_ids, device='cuda').unsqueeze(0)
            output = model(input_ids)
            outputs.append({key: val.cpu() for key, val in output.items()})

    pdb_list = [convert_outputs_to_pdb(output) for output in outputs]

    protein_identifiers = df[i:i+batch_size].Entry.tolist()
    for identifier, pdb in zip(protein_identifiers, pdb_list):
        print(f"Writing {output_dir}/{identifier}.pdb")
        with open(f"{output_dir}/{identifier}.pdb", "w") as f:
            f.write("".join(pdb))

