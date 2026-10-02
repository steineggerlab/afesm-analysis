# Supp. Fig. 10a: metadata of the clusters where the 45 novel folds are found, compared to the other ESM-only non-singleton clusters
# nMem: members of the foldseek cluster, nAllMem: members of the MMseqs2 and foldseek clusters combined,
# repPlddt: pLDDT of the representative, repLen: length of the representative
# Input from novel_fold_cluster_commands.sh
import os
import pandas as pd
import matplotlib.pyplot as plt
import matplotlib.ticker as mticker
import numpy as np

OUT_DIR = "/share/afesm6/jupyter/output"
os.makedirs(OUT_DIR, exist_ok=True)

cols = ['repID','isOnlyESM','nMem','nAllMem','repPlddt','avgPlddt',
        'avgAllPlddt','repLen','avgLen','avgAllLen','LCAtaxID','nBiome','LCBID']

novel = pd.read_csv(
    '/share/afesm6/50_novel_struct_dl/novel_domain_ids-repID_isOnlyESM_nMem_nAllMem_repPlddt_avgPlddt_avgAllPlddt_repLen_avgLen_avgAllLen_LCAtaxID_nBiome_LCBID.tsv',
    sep='\t', header=None, names=cols)
afesm = pd.read_csv(
    '/share/afesm6/39_share_db/2-repID_isOnlyESM_nMem_nAllMem_repPlddt_avgPlddt_avgAllPlddt_repLen_avgLen_avgAllLen_LCAtaxID_nBiome_LCBID.tsv',
    sep='\t', header=None, names=cols)

plot_cols = ['nMem','nAllMem','repPlddt','repLen']
log_cols  = {'nMem','nAllMem'}
plddt_cols = {'repPlddt','avgPlddt','avgAllPlddt'}

n = len(plot_cols)

afesm_esmonly = afesm[(afesm['nMem'] >= 2) & (afesm['isOnlyESM'] == 1)]

fig, axes = plt.subplots(1, n, figsize=(2.6 * n, 4))
for ax, col in zip(axes, plot_cols):
    data = [afesm_esmonly[col].dropna().values, novel[col].dropna().values]
    bp = ax.boxplot(data, labels=['ESM-only\nclusters', 'Novel domain\nclusters'],
                    showfliers=False, patch_artist=True, widths=0.35, vert=True)
    for patch, c in zip(bp['boxes'], ['#4C72B0', '#DD8452']):
        patch.set_facecolor(c)
        patch.set_alpha(0.8)
    for med in bp['medians']:
        med.set_color('black')
    ax.set_title(col)
    ax.set_ylabel(col)
    if col in plddt_cols:
        ax.set_ylim(0, 100)
    if col in log_cols:
        ax.set_yscale('log')
        ax.yaxis.set_major_locator(
            mticker.LogLocator(base=10, subs=np.arange(1, 10), numticks=100))
        ax.yaxis.set_minor_locator(mticker.NullLocator())
        ax.yaxis.set_major_formatter(mticker.FuncFormatter(lambda x, _: f'{int(x):,}'))
plt.tight_layout()
plt.savefig(os.path.join(OUT_DIR, 'novel_fold_cluster_metadata.png'), dpi=120, bbox_inches='tight')
plt.savefig(os.path.join(OUT_DIR, 'novel_fold_cluster_metadata.svg'), bbox_inches='tight')
plt.close()
