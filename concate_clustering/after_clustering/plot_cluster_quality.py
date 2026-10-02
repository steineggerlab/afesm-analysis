# Fig. 2a: distribution of the average member-to-representative lDDT and TM-score of the non-singleton AFESM clusters
# Input from cluster_quality_commands.sh
import os
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns

IN_FILE = "/share/afesm6/01_cluster_quality/afesm30_repseq_foldseek_clu_nonsingleton-repId_avgLddt_avgTmscore.tsv"
OUT_DIR = "/share/afesm6/jupyter/output"
os.makedirs(OUT_DIR, exist_ok=True)

# read lddt
lddts = {}
tm_scores = {}
with open(IN_FILE) as f:
    for line in f:
        tokens = line.strip().split()
        if not tokens:
            break
        repId = tokens[0]
        lddts[repId] = float(tokens[1])
        tm_scores[repId] = float(tokens[2])

np_lddts = np.array(list(lddts.values()))
np_tm_scores = np.array(list(tm_scores.values()))

# median value (for vertical lines)
median_lddts = np.median(np_lddts)
median_tm_scores = np.median(np_tm_scores)
print(f"median of lddts: {median_lddts}")
print(f"median of tm-score: {median_tm_scores}")

colors = ['#FFCC1B', '#46C8F5', '#E63334']

# boxplot
plt.figure(figsize=(2, 4))
plt.boxplot([np_lddts, np_tm_scores], showfliers=False, labels=['LDDT', 'TM-score'], widths=0.5)
plt.ylim([0, 1.1])
plt.tight_layout()
plt.ylabel('score')
plt.savefig(os.path.join(OUT_DIR, 'cluster_quality_lddt_tmscore_boxplot.svg'))
plt.close()

# kde lines of the histograms (to get the density curves)
lddt_plot = sns.histplot(np_lddts, kde=True, color=colors[0], label="lDDT")
tm_scores_plot = sns.histplot(np_tm_scores, kde=True, color=colors[1], label="TM-score")

line = lddt_plot.get_lines()[0]
lddt_xd = line.get_xdata()
lddt_yd = line.get_ydata()

line = tm_scores_plot.get_lines()[1]
tm_scores_xd = line.get_xdata()
tm_scores_yd = line.get_ydata()
plt.close()

# density with medians
fig = plt.figure()
gs = fig.add_gridspec(1, 4)
ax1 = fig.add_subplot(gs[0, 0:3])

ax1.plot(lddt_xd, lddt_yd, color=colors[0], label='lDDT')
ax1.plot(tm_scores_xd, tm_scores_yd, color=colors[1], label='TM-score')

ax1.set_xlabel('score')
ax1.set_xticks(np.arange(0, 1.25, 0.25))
ax1.set_ylabel('density')

plt.axvline(median_lddts, c=colors[0], dashes=(2, 2))
plt.axvline(median_tm_scores, c=colors[1], dashes=(2, 2))

ax1.legend()
plt.xticks(rotation=-35, ha='left')
plt.savefig(os.path.join(OUT_DIR, 'cluster_quality_lddt_tmscore_density.svg'))
