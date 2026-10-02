#!/usr/bin/env python3
# Supp. Fig. 11: structural stability of the 45 novel fold models after FastRelax
# Cα-RMSD from novel_fold_fastrelax.py, lDDT and qTM-score from the Foldseek alignment (novel_fold_fastrelax_commands.sh)
# pipeline: 12 ESMFold novel folds, abandoned: 33 AF2-ColabFold novel folds
import os, re
import pandas as pd
import matplotlib.pyplot as plt
from matplotlib.lines import Line2D

BASE     = "/share/afesm6/50_novel_struct_dl"
RESULT   = "/share/afesm6/52_fastrelax/aln/result.tsv"
SUMMARY  = "/share/afesm6/52_fastrelax/output/fastrelax_summary.tsv"
PIPELINE = f"{BASE}/novel_domain_pipeline.tsv"
OUT_DIR  = "/share/afesm6/jupyter/output"
C = {"pipeline": "#C44E52", "abandoned": "#4C72B0"}

def base_id(s):
    return re.sub(r"_\d+$", "", s)

def clean_name(s):
    s = s.rsplit(".pdb", 1)[0]
    s = re.sub(r"_relaxed$", "", s)
    return s

pipe_ids = set()
with open(PIPELINE) as f:
    for line in f:
        line = line.strip()
        if line:
            pipe_ids.add(base_id(line.split()[0]))

# result.tsv 에서는 lddt, qtmscore 만 사용
aln = pd.read_csv(RESULT, sep="\t",
                  names=["query", "target", "lddt", "qtmscore", "alntmscore", "rmsd"])
aln["name"] = aln["query"].apply(clean_name)
aln = aln[["name", "lddt", "qtmscore"]]

# ca_rmsd 는 summary 에서만 사용
rm = pd.read_csv(SUMMARY, sep="\t")
rm = rm[pd.to_numeric(rm["ca_rmsd"], errors="coerce").notna()].copy()
rm["ca_rmsd"] = rm["ca_rmsd"].astype(float)
rm = rm[["name", "ca_rmsd"]]

df = rm.merge(aln, on="name", how="inner")
df["entryId"] = df["name"].str.extract(r"^(MGYP\d+)")
df["group"] = df["entryId"].apply(lambda e: "pipeline" if e in pipe_ids else "abandoned")

n_pipe = (df["group"] == "pipeline").sum()
n_aban = (df["group"] == "abandoned").sum()

PAIRS = [
    ("lddt",     "ca_rmsd", "lddt",     "ca_rmsd"),
    ("qtmscore", "ca_rmsd", "qtmscore", "ca_rmsd"),
    ("qtmscore", "lddt",    "qtmscore", "lddt"),
]
fig, axes = plt.subplots(1, 3, figsize=(15, 4.5))
for ax, (xc, yc, xl, yl) in zip(axes, PAIRS):
    for g in ["abandoned", "pipeline"]:
        d = df[df["group"] == g]
        ax.scatter(d[xc], d[yc], s=35, alpha=0.8, edgecolors="white",
                   linewidths=0.5, color=C[g])
    r = df[[xc, yc]].corr().iloc[0, 1]
    ax.text(0.03, 0.97, f"r = {r:.2f}", transform=ax.transAxes,
            ha="left", va="top", fontsize=10,
            bbox=dict(boxstyle="round,pad=0.3", fc="white", ec="0.7"))
    ax.set_xlabel(xl, fontsize=11)
    ax.set_ylabel(yl, fontsize=11)
    if xc in ("lddt", "qtmscore"):
        ax.set_xlim(0, 1.0)
    if yc in ("lddt", "qtmscore"):
        ax.set_ylim(0, 1.0)

handles = [Line2D([0], [0], marker="o", color="w", markerfacecolor=C[g],
                  markersize=8, label=f"{lab} (n={n})")
           for g, lab, n in [("pipeline", "From the pipeline", n_pipe),
                             ("abandoned", "Abandoned domains", n_aban)]]
axes[0].legend(handles=handles, frameon=False, fontsize=9, loc="upper right")

os.makedirs(OUT_DIR, exist_ok=True)
fig.tight_layout()
png = os.path.join(OUT_DIR, "novel_fold_fastrelax_scatter.png")
svg = os.path.join(OUT_DIR, "novel_fold_fastrelax_scatter.svg")
fig.savefig(png, dpi=150, bbox_inches="tight")
fig.savefig(svg, bbox_inches="tight")
print(f"saved: {png}\nsaved: {svg}")
print(f"[merged] n={len(df)}  pipeline={n_pipe}  abandoned={n_aban}")
