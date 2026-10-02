# Supp. Fig. 9e: Foldseek alignment of the rescued domains (AF2-ColabFold, query) to their ESMatlas counterparts (target)
# Input from rescued_domain_alignment_commands.sh

import os
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
import numpy as np

OUT_DIR = "/share/afesm6/jupyter/output"
os.makedirs(OUT_DIR, exist_ok=True)

df3 = pd.read_csv(
    "/share/afesm6/50_novel_struct_dl/rescued_domain-domainId_colabPlddt_esmPlddt_lddt_alntmscore_qtmscore.tsv",
    names=["domainId", "colabPlddt", "esmPlddt", "lddt", "alntmscore", "qtmscore"],
    delimiter="\t",
    index_col=0
).dropna(subset=["colabPlddt", "lddt"])

print(f"Data loaded. Total points: {len(df3):,}")

x = df3["qtmscore"].values
y = df3["lddt"].values

g = sns.JointGrid(x=x, y=y, space=0, height=6)

# hexbin 객체 직접 확보
hb = g.ax_joint.hexbin(x, y, gridsize=50, cmap="mako", mincnt=1)

hist_kwargs = dict(bins=50, color="navy", alpha=0.7, edgecolor="black")
g.ax_marg_x.hist(x, **hist_kwargs)
g.ax_marg_y.hist(y, orientation="horizontal", **hist_kwargs)

xmin, xmax = -0.05, 1.05
ymin, ymax = -0.05, 1.05
g.ax_joint.set_xlim([xmin, xmax])
g.ax_joint.set_ylim([ymin, ymax])
g.ax_marg_x.set_xlim([xmin, xmax])
g.ax_marg_y.set_ylim([ymin, ymax])

g.figure.suptitle("Rescued Domains: qTMscore vs LDDT", y=1.05)
g.ax_joint.set_xlabel("qtmscore")
g.ax_joint.set_ylabel("lddt")

g.ax_joint.axvline(x=0.5, color='red', linestyle='--', linewidth=1.5)
g.ax_joint.axhline(y=0.5, color='red', linestyle='--', linewidth=1.5)

# 컬러바 (joint 오른쪽 바깥)
cax = g.figure.add_axes([1.0, 0.1, 0.02, 0.5])
cb = g.figure.colorbar(hb, cax=cax)
cb.set_label("Count")

plt.savefig(os.path.join(OUT_DIR, "Rescued-qTMscore-LDDT.svg"), bbox_inches="tight")
print("Done.")
