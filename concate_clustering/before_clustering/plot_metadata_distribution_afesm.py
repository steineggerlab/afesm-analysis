# Fig. 1a: metadata distribution over AFDB (left) and ESMatlas (right) before clustering
# Counts come from metadata_distribution_commands.sh (/share/afesm6/12_plain_distributions/)
import os
import matplotlib.pyplot as plt
import matplotlib.ticker as mticker

OUT_DIR = "/share/afesm6/jupyter/output"

# ── 전체 entry 수 ──
n_afdb = 214683829   # AFDB entries
n_esm  = 605776560   # ESMatlas entries
# ── 메트릭별 annotated 개수 ──
# 각 dict: 해당 메트릭에서 AFDB / ESM 방향으로 annotated 된 개수
Biome    = {'AFDB': 0.0,   'ESM': 361790612}   # biome은 ESM만 (biome)
Pfam     = {'AFDB': 154961260, 'ESM': 283414470}   # pfam_mgyp_afdb
Fragment = {'AFDB': 510355536-489509558,  'ESM': 489509558}   # frag - frag_esm, frag_esm
Taxonomy = {'AFDB': 204789716, 'ESM': 0}   # tax-afdbtax_nafdb_esmtax_nesm (ESMatlas taxonomy is predicted later)
metrics = {'Biome': Biome, 'Pfam': Pfam, 'Fragment': Fragment, 'Taxonomy': Taxonomy}
# ─────────────────────────────────────────
names = list(metrics.keys())
y = list(range(len(names))); h = 0.9
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
plt.savefig(os.path.join(OUT_DIR, 'metadata_distribution_afesm.svg'))
plt.savefig(os.path.join(OUT_DIR, 'metadata_distribution_afesm.png'), dpi=300)
total = n_afdb + n_esm
print(f"AFDB ratio: {n_afdb/total*100:.2f}%")
print(f"ESM  ratio: {n_esm/total*100:.2f}%")
print()
for name in names:
    a = metrics[name]['AFDB']
    e = metrics[name]['ESM']
    n_sum = n_afdb + n_esm
    print(f"{name} of AFDB: {a/n_sum*100:.2f}%\t{name} of ESM: {e/n_sum*100:.2f}%")
