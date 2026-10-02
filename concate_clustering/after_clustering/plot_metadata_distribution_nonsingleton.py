# Fig. 2: metadata distribution over the AFDB (left) and ESMatlas (right) members of the non-singleton AFESM clusters
# Counts come from nonsingleton_metadata_distribution_commands.sh (/share/afesm6/16_clu_plain_dist/)
import os
import matplotlib.pyplot as plt
import matplotlib.ticker as mticker

OUT_DIR = "/share/afesm6/jupyter/output"

# ── 전체 멤버 수 ──
n_afdb = 165812116   # AFDB nonsingleton 클러스터 멤버 수
n_esm  = 364787724   # ESM  nonsingleton 클러스터 멤버 수 (nonsingleton_nEsm)
# ── 메트릭별 annotated 개수 ──
# 각 dict: 해당 메트릭에서 AFDB / ESM 방향으로 annotated 된 개수
Biome    = {'AFDB': 0.0,   'ESM': 249699500}   # biome은 ESM만 (nonsingleton_biome-mgypBiome_mgyp_afdbBiome_afdb)
Pfam     = {'AFDB': 130706911, 'ESM': 241977505}   # nonsingleton_pfam-mgypPfam_mgyp_afdbPfam_afdb
Fragment = {'AFDB': 14910348,  'ESM': 279272199}   # nonsingleton_frag-mgyp_afdb
Taxonomy = {'AFDB': 157898461, 'ESM': 336501005}   # nonsingleton_tax-mgypTax_mgyp_afdbTax_afdb
metrics = {'Biome': Biome, 'Pfam': Pfam, 'Fragment': Fragment, 'Taxonomy': Taxonomy}
# ─────────────────────────────────────────
names = list(metrics.keys())
y = list(range(len(names))); h = 0.6
fig, ax = plt.subplots(figsize=(6, 4))
for i, name in enumerate(names):
    a_anno = metrics[name]['AFDB']
    e_anno = metrics[name]['ESM']
    # 왼쪽 AFDB (음수)
    ax.barh(i, -a_anno, height=h, color='#0C3372')
    ax.barh(i, -(n_afdb - a_anno), height=h, left=-a_anno, color='gray')
    # 오른쪽 ESM (양수)
    ax.barh(i, e_anno, height=h, color='#0C3372')
    ax.barh(i, n_esm - e_anno, height=h, left=e_anno, color='gray')
# 범례용 더미
ax.barh(0, 0, color='#0C3372', label='annotated')
ax.barh(0, 0, color='gray', label='unannotated')
ax.axvline(0, color='black', lw=0.8)
ax.set_yticks(y); ax.set_yticklabels(names)
ax.margins(y=0.05)   # 위아래 여백 축소
ax.set_xlabel("count (million)   ← AFDB   |   ESM →")
ax.xaxis.set_major_formatter(mticker.FuncFormatter(lambda x, _: f"{abs(int(x))}"))
ax.legend()
plt.tight_layout()
os.makedirs(OUT_DIR, exist_ok=True)
plt.savefig(os.path.join(OUT_DIR, 'metadata_distribution_nonsingleton.svg'))
plt.savefig(os.path.join(OUT_DIR, 'metadata_distribution_nonsingleton.png'), dpi=300)
total = n_afdb + n_esm
print(f"AFDB ratio: {n_afdb/total*100:.2f}%")
print(f"ESM  ratio: {n_esm/total*100:.2f}%")
print()
for name in names:
    a = metrics[name]['AFDB']
    e = metrics[name]['ESM']
    print(f"{name} of AFDB: {a/total*100:.2f}%\t{name} of ESM: {e/total*100:.2f}%")
