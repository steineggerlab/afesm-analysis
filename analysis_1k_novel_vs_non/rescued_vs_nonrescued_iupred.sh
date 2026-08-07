#!/usr/bin/env bash
# rescued_vs_unrescued_iupred3.sh
#
# Compare predicted disorder (IUPred3) between AF2-ColabFold rescued and
# non-rescued domains from the 2.3M low-quality, CATH-unmatched set.
#
# Inputs (expected in data/):
#   allreps_lowqual_domains                          – 2,313,952 domain rows (col1=domain_id, col4=range)
#   Novel_folds_starting_point_AFESM.Good_quality_domains.tsv – rescued domain ModelIDs
#   protein_sequences.fasta                          – full-length protein sequences for sampled domains
#
# Requires: iupred3/ directory with iupred3.py
#
# Usage: bash scripts/rescued_vs_unrescued_iupred3.sh

set -euo pipefail

SEED=42
N=1000
DATADIR=data
OUTDIR=rescuable_vs_un
IUPRED3=iupred3/iupred3.py

mkdir -p "$OUTDIR"

# ── Step 1: Extract rescued domain IDs from Good_quality_domains.tsv ──
# ModelID format: MGYP000000296210_01_13_118_unrelaxed_...
# Domain ID = first two underscore-delimited fields
awk -F'\t' 'NR>1 {
    split($1, a, "_")
    print a[1] "_" a[2]
}' "$DATADIR/Novel_folds_starting_point_AFESM.Good_quality_domains.tsv" \
  | sort -u > "$OUTDIR/rescued_all.ids"

# ── Step 2: Split allreps into rescued / unrescued ──
awk -F'\t' 'NR==FNR {rescued[$1]; next}
     ($1 in rescued) {print $1 > "'"$OUTDIR"'/rescued_pool.ids"}
     !($1 in rescued) {print $1 > "'"$OUTDIR"'/unrescued_pool.ids"}
' "$OUTDIR/rescued_all.ids" "$DATADIR/allreps_lowqual_domains"

# ── Step 3: Random-sample 1000 from each (seed 42) ──
# Deterministic seed via /dev/urandom replacement
seed_file=$(mktemp)
python3 -c "
import struct, random
random.seed($SEED)
with open('$seed_file','wb') as f:
    f.write(bytes(random.getrandbits(8) for _ in range(4096)))
"
shuf --random-source="$seed_file" "$OUTDIR/rescued_pool.ids"   | head -n $N > "$OUTDIR/rescued_${N}.ids"
shuf --random-source="$seed_file" "$OUTDIR/unrescued_pool.ids" | head -n $N > "$OUTDIR/unrescued_${N}.ids"
rm -f "$seed_file"

# ── Step 4: Extract domain ranges for the 2000 sampled domains ──
cat "$OUTDIR/rescued_${N}.ids" "$OUTDIR/unrescued_${N}.ids" \
  | sort > "$OUTDIR/sampled_2000.ids"

awk -F'\t' 'NR==FNR {ids[$1]; next}
     ($1 in ids) {print $1 "\t" $4}
' "$OUTDIR/sampled_2000.ids" "$DATADIR/allreps_lowqual_domains" \
  > "$DATADIR/all_2000_domain_ranges.tsv"

# Unique protein IDs (strip domain suffix)
awk -F'\t' '{sub(/_[0-9]+$/, "", $1); print $1}' "$DATADIR/all_2000_domain_ranges.tsv" \
  | sort -u > "$DATADIR/protein_ids_needed.txt"

echo "Sampled $(wc -l < "$OUTDIR/rescued_${N}.ids") rescued + $(wc -l < "$OUTDIR/unrescued_${N}.ids") unrescued domains"
echo "Need sequences for $(wc -l < "$DATADIR/protein_ids_needed.txt") unique proteins"
echo "Provide FASTA as: $DATADIR/protein_sequences.fasta"

# ── Step 5: Run IUPred3 on each protein and compute per-domain scores ──
# Expects protein_sequences.fasta to exist at this point.
FASTA="$DATADIR/protein_sequences.fasta"
if [[ ! -s "$FASTA" ]]; then
    echo "ERROR: $FASTA not found. Provide sequences and re-run from this step."
    exit 1
fi

RESULTS="$DATADIR/iupred_results.tsv"
echo -e "domain_id\tgroup\trange\tnum_residues\tmean_iupred\tpct_disordered" > "$RESULTS"

# Build group lookup
declare -A GROUP
while IFS= read -r id; do GROUP["$id"]="rescued"; done < "$OUTDIR/rescued_${N}.ids"
while IFS= read -r id; do GROUP["$id"]="unrescued"; done < "$OUTDIR/unrescued_${N}.ids"

# Run IUPred3 per protein, then slice scores to each domain range
TMPSEQ=$(mktemp --suffix=.fasta)
TMPIUP=$(mktemp)

while IFS=$'\t' read -r domain_id range; do
    protein_id="${domain_id%_*}"
    group="${GROUP[$domain_id]}"

    # Extract single protein sequence from FASTA
    awk -v pid="$protein_id" '
        BEGIN {found=0}
        /^>/ {found = (index($0, pid) > 0) ? 1 : 0; next}
        found {printf "%s", $0}
        END {print ""}
    ' "$FASTA" > "${TMPSEQ%.fasta}.seq"

    # Prepend FASTA header for IUPred3
    echo ">$protein_id" > "$TMPSEQ"
    cat "${TMPSEQ%.fasta}.seq" >> "$TMPSEQ"

    # Run IUPred3 (long mode, no smoothing)
    python3 "$IUPRED3" "$TMPSEQ" long -s no > "$TMPIUP" 2>/dev/null

    # Parse IUPred3 output: lines without '#' have columns: pos AA score
    # Slice to domain range(s) — range can be "8-32_117-165" (discontinuous)
    python3 -c "
import sys
scores = []
with open('$TMPIUP') as f:
    for line in f:
        if line.startswith('#') or line.strip() == '':
            continue
        parts = line.split()
        scores.append(float(parts[2]))

# Parse range segments
segments = '$range'.split('_')
domain_scores = []
for seg in segments:
    start, end = seg.split('-')
    s, e = int(start) - 1, int(end)  # 1-based inclusive to 0-based
    domain_scores.extend(scores[s:e])

n = len(domain_scores)
if n == 0:
    print('$domain_id\t$group\t$range\t0\tNA\tNA')
else:
    mean_score = sum(domain_scores) / n
    pct_dis = 100.0 * sum(1 for s in domain_scores if s > 0.5) / n
    print(f'$domain_id\t$group\t$range\t{n}\t{mean_score:.6f}\t{pct_dis:.2f}')
" >> "$RESULTS"

done < "$DATADIR/all_2000_domain_ranges.tsv"

rm -f "$TMPSEQ" "${TMPSEQ%.fasta}.seq" "$TMPIUP"

echo "Done. Results: $RESULTS ($(tail -n +2 "$RESULTS" | wc -l) domains)"
