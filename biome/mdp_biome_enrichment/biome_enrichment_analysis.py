#!/usr/bin/env python3
"""Analyse biome label enrichment in Novel vs Non-novel MDPs.
Tasks:
1. Recompute stats with correct LCB definition (manuscript pipeline)
2. Distribution plots (ECDF, not boxplot) for key variables - Eli's request
3. 2D scatter: nAllMem vs nDomain (or repLen), coloured by set
4. Check if nAllMem explains the biome gap (stratified analysis)
"""

import gzip
import math
import os

# ---- Config ----
CLUSTER_DATA = "data/2-repID_isOnlyESM_nMem_nAllMem_repPlddt_avgPlddt_avgAllPlddt_repLen_avgLen_avgAllLen_LCAtaxID_nBiome_LCBID.tsv.gz"
BIOME_FILE = "data/afesm30_biome_specific_nonsingletons-repId_nBiome_nLcaLen_biomeLca.tsv"
NOVEL_IDS = "data/novel_mdp_ids.txt"          # 11,941 novel MDP protein IDs
MDP_IDS = "data/mdp_ids.txt"                  # 393,793 MDP background protein IDs
NOVEL_HL = "data/legacy_novel_ids_5203.txt"    # 5,203 H-level novel IDs
NONNOV_HL = "data/non_novel_hlevel_ids_134576.txt"  # 134,576 H-level non-novel IDs
DOMAIN_ROWS = "data/mdp_domain_rows_hlevel.tsv.gz"  # Domain rows for H-level set
OUTDIR = "output"

os.makedirs(OUTDIR, exist_ok=True)

# ---- Load ID sets ----
def load_ids(path):
    ids = set()
    with open(path) as f:
        for line in f:
            ids.add(line.strip())
    return ids

novel_full = load_ids(NOVEL_IDS)
mdp_all = load_ids(MDP_IDS)
novel_hl = load_ids(NOVEL_HL)
nonnov_hl = load_ids(NONNOV_HL)

# ---- Load biome labels (manuscript pipeline) ----
has_lcb = set()
with open(BIOME_FILE) as f:
    for line in f:
        rep_id = line.split("\t")[0]
        has_lcb.add(rep_id)

print(f"Biome file: {len(has_lcb):,} clusters with LCB")

# ---- Load cluster data for MDP IDs ----
# Columns (0-indexed): 0=repID, 1=isOnlyESM, 2=nMem, 3=nAllMem,
# 4=repPlddt, 5=avgPlddt, 6=avgAllPlddt, 7=repLen, 8=avgLen,
# 9=avgAllLen, 10=LCAtaxID, 11=nBiome, 12=LCBID

data = {}  # repID -> dict
with gzip.open(CLUSTER_DATA, "rt") as f:
    for line in f:
        parts = line.rstrip("\n").split("\t")
        rid = parts[0]
        if rid not in mdp_all:
            continue
        if parts[1] != "1":  # ESM-only
            continue
        data[rid] = {
            "nMem": int(parts[2]),
            "nAllMem": int(parts[3]),
            "repPlddt": float(parts[4]),
            "repLen": int(parts[7]),
            "has_lcb": rid in has_lcb,
        }

print(f"Loaded {len(data):,} ESM-only MDP cluster records")

# ---- Load domain counts per protein ----
ndom = {}
with gzip.open(DOMAIN_ROWS, "rt") as f:
    header = True
    for line in f:
        if header:
            header = False
            continue
        parts = line.split("\t")
        prot = parts[1]
        ndom[prot] = ndom.get(prot, 0) + 1

# ---- Build per-set arrays ----
sets = {
    "novel_full": novel_full,
    "nonnov_full": mdp_all - novel_full,
    "novel_hl": novel_hl,
    "nonnov_hl": nonnov_hl,
}

arrays = {}
for sname, id_set in sets.items():
    arr = {"nMem": [], "nAllMem": [], "repLen": [], "repPlddt": [],
           "has_lcb": [], "nDom": []}
    for rid in id_set:
        if rid not in data:
            continue
        d = data[rid]
        arr["nMem"].append(d["nMem"])
        arr["nAllMem"].append(d["nAllMem"])
        arr["repLen"].append(d["repLen"])
        arr["repPlddt"].append(d["repPlddt"])
        arr["has_lcb"].append(1 if d["has_lcb"] else 0)
        arr["nDom"].append(ndom.get(rid, 0))
    arrays[sname] = arr

# ---- Print summary stats ----
def pct(vals):
    return sum(vals) * 100 / len(vals) if vals else 0

def mean(vals):
    return sum(vals) / len(vals) if vals else 0

def median(vals):
    s = sorted(vals)
    return s[len(s)//2] if s else 0

print("\n" + "="*70)
print("FULL SET: Novel (11,941) vs Non-novel (381,852)")
print("="*70)
for sname in ["novel_full", "nonnov_full"]:
    a = arrays[sname]
    n = len(a["nMem"])
    print(f"\n{sname} (n={n:,})")
    print(f"  % with LCB:   {pct(a['has_lcb']):.2f}%")
    print(f"  mean nMem:    {mean(a['nMem']):.3f}  median: {median(a['nMem'])}")
    print(f"  mean nAllMem: {mean(a['nAllMem']):.1f}  median: {median(a['nAllMem'])}")
    print(f"  mean repLen:  {mean(a['repLen']):.1f}  median: {median(a['repLen'])}")
    print(f"  mean nDom:    {mean(a['nDom']):.2f}  median: {median(a['nDom'])}")

print("\n" + "="*70)
print("H-LEVEL FILTERED: Novel (5,203) vs Non-novel (134,576)")
print("="*70)
for sname in ["novel_hl", "nonnov_hl"]:
    a = arrays[sname]
    n = len(a["nMem"])
    print(f"\n{sname} (n={n:,})")
    print(f"  % with LCB:   {pct(a['has_lcb']):.2f}%")
    print(f"  mean nMem:    {mean(a['nMem']):.3f}  median: {median(a['nMem'])}")
    print(f"  mean nAllMem: {mean(a['nAllMem']):.1f}  median: {median(a['nAllMem'])}")
    print(f"  mean repLen:  {mean(a['repLen']):.1f}  median: {median(a['repLen'])}")
    print(f"  mean nDom:    {mean(a['nDom']):.2f}  median: {median(a['nDom'])}")

# ---- Write per-protein table for plotting ----
out_tsv = os.path.join(OUTDIR, "mdp_biome_analysis_data.tsv")
with open(out_tsv, "w") as f:
    f.write("repID\tset_full\tset_hl\tnMem\tnAllMem\trepLen\trepPlddt\thas_lcb\tnDom\n")
    for rid in data:
        sf = "novel" if rid in novel_full else "non_novel"
        sh = "novel" if rid in novel_hl else ("non_novel" if rid in nonnov_hl else "NA")
        d = data[rid]
        nd = ndom.get(rid, 0)
        lcb = 1 if d["has_lcb"] else 0
        f.write(f"{rid}\t{sf}\t{sh}\t{d['nMem']}\t{d['nAllMem']}\t{d['repLen']}\t{d['repPlddt']:.1f}\t{lcb}\t{nd}\n")

print(f"\nWrote {out_tsv}")

# ---- Stratified analysis: biome rate by nAllMem bins ----
print("\n" + "="*70)
print("STRATIFIED: % LCB by nAllMem bin (full set)")
print("="*70)

bins = [(1, 5), (6, 20), (21, 50), (51, 100), (101, 500), (501, 99999999)]
bin_labels = ["1-5", "6-20", "21-50", "51-100", "101-500", "500+"]

for sname in ["novel_full", "nonnov_full"]:
    a = arrays[sname]
    print(f"\n{sname}:")
    for (lo, hi), bl in zip(bins, bin_labels):
        n_bin = 0
        n_lcb = 0
        for i in range(len(a["nAllMem"])):
            if lo <= a["nAllMem"][i] <= hi:
                n_bin += 1
                n_lcb += a["has_lcb"][i]
        if n_bin > 0:
            print(f"  nAllMem {bl:>8s}: {n_lcb}/{n_bin} = {n_lcb*100/n_bin:.1f}%  (n={n_bin:,})")

# ---- Correlation: nAllMem vs nDom ----
print("\n" + "="*70)
print("CORRELATION: nAllMem vs nDom")
print("="*70)

def pearson_r(xs, ys):
    n = len(xs)
    mx = sum(xs) / n
    my = sum(ys) / n
    cov = sum((x - mx) * (y - my) for x, y in zip(xs, ys))
    sx = math.sqrt(sum((x - mx)**2 for x in xs))
    sy = math.sqrt(sum((y - my)**2 for y in ys))
    if sx == 0 or sy == 0:
        return 0
    return cov / (sx * sy)

for sname in ["novel_full", "nonnov_full"]:
    a = arrays[sname]
    r = pearson_r(a["nAllMem"], a["nDom"])
    print(f"  {sname}: r = {r:.4f} (n={len(a['nAllMem']):,})")

# Also nAllMem vs repLen
print("\nCORRELATION: nAllMem vs repLen")
for sname in ["novel_full", "nonnov_full"]:
    a = arrays[sname]
    r = pearson_r(a["nAllMem"], a["repLen"])
    print(f"  {sname}: r = {r:.4f}")

print("\nCORRELATION: repLen vs nDom")
for sname in ["novel_full", "nonnov_full"]:
    a = arrays[sname]
    r = pearson_r(a["repLen"], a["nDom"])
    print(f"  {sname}: r = {r:.4f}")

print("\nDone.")
