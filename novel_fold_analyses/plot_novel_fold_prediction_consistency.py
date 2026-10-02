#!/usr/bin/env python3
# Supp. Fig. 12: prediction consistency of the 45 novel folds
# a, b: lDDT and qTM-score of the reference model (ESMFold model for the 12 ESMFold folds, ColabFold rank_001 for the 33 rescued folds)
#       aligned to the ColabFold rank_001-005 models and the ESMFold2 model
# c: average pLDDT of the ColabFold, ESMFold and ESMFold2 models
# Inputs from novel_fold_prediction_consistency_commands.sh
import pandas as pd
import matplotlib.pyplot as plt
from matplotlib.lines import Line2D

PIPE = "/share/afesm6/50_novel_struct_dl/novel_domain_pipeline.tsv"
TSV_ESM = "/share/afesm6/51_5model/compare_esmFold/novel_concat_db_aln.tsv"
TSV_SELF = "/share/afesm6/51_5model/database/novel_domain_colabfold.tsv"
TSV_ESM2 = "/share/afesm6/51_5model/esmfold2/alignment/esmfold2_aln.tsv"
PLDDT_CF = "/share/afesm6/51_5model/plddt/colabfold-domain_plddt.tsv"
PLDDT_E1 = "/share/afesm6/51_5model/plddt/esmfold-domain_plddt.tsv"
PLDDT_E2 = "/share/afesm6/51_5model/plddt/esmfold2-domain_plddt.tsv"
OUT = "/share/afesm6/jupyter/output/novel_fold_prediction_consistency.png"
GAP = 2

pipe_entries = set()
with open(PIPE) as f:
    for line in f:
        p = line.rstrip("\n").split("\t")
        if p and p[0]:
            pipe_entries.add(p[0])

esm = pd.read_csv(TSV_ESM, sep="\t", names=["query", "target", "lddt", "qtmscore"])
esm["domainId"] = esm["target"].str.extract(r"^(MGYP\d+_\d+)")
esm["entryId"] = esm["target"].str.extract(r"^(MGYP\d+)")
esm["rank"] = esm["target"].str.extract(r"rank_(\d+)").astype(int)
esm = esm[esm["entryId"].isin(pipe_entries)].copy()
esm["group"] = "ESMfold"

slf = pd.read_csv(TSV_SELF, sep="\t",
                  names=["query", "target", "lddt", "qtmscore", "alntmscore", "evalue"])
slf["domainId"] = slf["target"].str.extract(r"^(MGYP\d+_\d+)")
slf["entryId"] = slf["target"].str.extract(r"^(MGYP\d+)")
slf["rank"] = slf["target"].str.extract(r"rank_(\d+)").astype(int)
slf = slf[~slf["entryId"].isin(pipe_entries)].copy()
slf["group"] = "rescued"

df = pd.concat([esm[["domainId", "rank", "lddt", "qtmscore", "group"]],
                slf[["domainId", "rank", "lddt", "qtmscore", "group"]]],
               ignore_index=True)

e2 = pd.read_csv(TSV_ESM2, sep="\t", header=None,
                 names=["query", "target", "lddt", "qtmscore", "alntmscore"])
e2["domainId"] = e2["query"].str.extract(r"^(MGYP\d+_\d+)")
e2 = e2.dropna(subset=["domainId"]).drop_duplicates("domainId").set_index("domainId")

# ---- pLDDT ----
pl_cf = pd.read_csv(PLDDT_CF, sep="\t")
pl_cf["rank"] = pd.to_numeric(pl_cf["rank"], errors="coerce")
pl_cf = pl_cf.dropna(subset=["rank"])
pl_cf["rank"] = pl_cf["rank"].astype(int)
plddt_p = pl_cf.pivot_table(index="domainId", columns="rank", values="avg_plddt")

pl_e1 = pd.read_csv(PLDDT_E1, sep="\t").drop_duplicates("domainId").set_index("domainId")
pl_e2 = pd.read_csv(PLDDT_E2, sep="\t").drop_duplicates("domainId").set_index("domainId")

lddt_p = df.pivot_table(index="domainId", columns="rank", values="lddt")
qtm_p  = df.pivot_table(index="domainId", columns="rank", values="qtmscore")
grp = df.groupby("domainId")["group"].first()

def second_max(row):
    vals = row.dropna().sort_values(ascending=False)
    return vals.iloc[1] if len(vals) >= 2 else (vals.iloc[0] if len(vals) else float("nan"))

max_lddt = lddt_p.max(axis=1)
second_lddt = lddt_p.apply(second_max, axis=1)

order_df = pd.DataFrame({"group": grp})
order_df["gkey"] = order_df["group"].map({"ESMfold": 0, "rescued": 1})
order_df["sortval"] = [
    max_lddt[d] if grp[d] == "ESMfold" else second_lddt[d]
    for d in order_df.index
]
order = order_df.sort_values(["gkey", "sortval"], ascending=[True, False]).index.tolist()

lddt_p = lddt_p.loc[order]
qtm_p  = qtm_p.loc[order]
plddt_p = plddt_p.reindex(order)
groups = grp.loc[order]
n_esm = (groups == "ESMfold").sum()

base_x = [i if i < n_esm else i + GAP for i in range(len(order))]

CF_COLOR = "#4477AA"
E2_COLOR = "#EE3377"
E1_COLOR = "#DDAA33"
RANK_MARK = {1: "o", 2: "s", 3: "D", 4: "^", 5: "v"}

# ESMFold/ESMFold2 왼쪽, ColabFold 오른쪽
E1_OFF = -0.40
E2_OFF = -0.28
RANK_OFF = {1: -0.10, 2: 0.02, 3: 0.14, 4: 0.26, 5: 0.38}
SEP = 0.50

fig, axes = plt.subplots(3, 1, figsize=(max(14, len(order) * 0.34), 13), sharex=True)

panels = [
    (axes[0], lddt_p, "lddt", "LDDT", (0, 1.05)),
    (axes[1], qtm_p, "qtmscore", "qTMscore", (0, 1.05)),
    (axes[2], plddt_p, "avg_plddt", "avg pLDDT", (0, 105)),
]

for ax, pv, col, ylab, ylim in panels:
    for i, x in enumerate(base_x[:-1]):
        if i + 1 == n_esm:
            continue
        ax.axvline(x + SEP, color="gray", ls="-", lw=0.4, alpha=0.35, zorder=0)

    for r in [1, 2, 3, 4, 5]:
        if r not in pv.columns:
            continue
        xs_r = [x + RANK_OFF[r] for x in base_x]
        ax.scatter(xs_r, pv[r].values, marker=RANK_MARK[r], c=CF_COLOR, s=34,
                   alpha=0.65, edgecolors="#22334d", linewidths=0.4, zorder=3)

    if col == "avg_plddt":
        e2_vals = [pl_e2["avg_plddt"].get(d, float("nan")) for d in order]
        e1_vals = [pl_e1["avg_plddt"].get(d, float("nan")) for d in order]
        ax.scatter([x + E1_OFF for x in base_x], e1_vals, marker="P", c=E1_COLOR, s=55,
                   edgecolors="none", zorder=4)
    else:
        e2_vals = [e2[col].get(d, float("nan")) for d in order]
    ax.scatter([x + E2_OFF for x in base_x], e2_vals, marker="*", c=E2_COLOR, s=70,
               edgecolors="none", zorder=4)

    ax.set_ylabel(ylab)
    ax.set_ylim(*ylim)
    ax.grid(True, axis="y", alpha=0.15)

esm_mid = (base_x[0] + base_x[n_esm - 1]) / 2
axes[0].text(esm_mid, 1.02, "from ESMfold", ha="center", va="bottom",
             transform=axes[0].get_xaxis_transform(), fontweight="bold")
if n_esm < len(order):
    res_mid = (base_x[n_esm] + base_x[-1]) / 2
    axes[0].text(res_mid, 1.02, "rescued", ha="center", va="bottom",
                 transform=axes[0].get_xaxis_transform(), fontweight="bold")

axes[-1].set_xticks(base_x)
axes[-1].set_xticklabels(order, rotation=90, fontsize=7)

handles = [Line2D([0], [0], marker=RANK_MARK[r], color="w",
                  markerfacecolor=CF_COLOR, markeredgecolor="#22334d", markeredgewidth=0.4,
                  markersize=8, alpha=0.8, label=f"ColabFold rank_{r:03d}")
           for r in [1, 2, 3, 4, 5]]
handles.append(Line2D([0], [0], marker="*", color="w",
                      markerfacecolor=E2_COLOR, markersize=12, label="ESMFold2"))
handles.append(Line2D([0], [0], marker="P", color="w",
                      markerfacecolor=E1_COLOR, markersize=10, label="ESMFold (pLDDT only)"))
axes[0].legend(handles=handles, loc="lower left", ncol=7, framealpha=0.9)

plt.tight_layout()
plt.savefig(OUT, dpi=150, bbox_inches="tight")
plt.savefig(OUT.replace(".png", ".svg"), bbox_inches="tight")
print(f"saved -> {OUT} (+svg)  (domains={len(order)}, ESMfold={n_esm}, rescued={len(order)-n_esm})")
