#!/usr/bin/env bash
# AFESM biome clusters: non-singleton clusters with >= 10 biome annotations and their LCB
# Fig. 2e: 43_biome_dist.ipynb (specificity_count, annotation count)
# Fig. 2f-h: 43_superkingdom_summary.ipynb (Thermal, Saline LCA)
# Supp. Fig. 2-5: taxonomy reports of the biome specific clusters (visualized with Pavian)
# Fig. 2i, Supp. Fig. 6: Foldseek search of the biome specific clusters against the non-specific clusters
set -euo pipefail

OUT_DIR="/share/afesm6/43_biome_nonsingleton"
mkdir -p "${OUT_DIR}"

# clusters with >= 10 biome annotations: repId, nBiome, nLcaLen, biomeLca
BIOME_CLUSTERS="/share/afesm6/39_share_db/pdb_search/afesm30_biome_specific.lookupids"
# non-singleton clusters: repId, nMem
NONSINGLETON="/share/afesm5/metadata/afesm30_repseq_foldseek_clu_nonsingleton-repId_nMem.tsv"
# LCA of all the cluster members (taxonomy/taxonomy_lca)
TAX_LCA="/share/afesm6/15_n_genus/tax_lca/afesm30_allMem_lca_blacklist"
AFESM_DB="/fast/esmfold/databases/afesm"

# clusters with >= 10 biome annotations
# afesm30-repId_nBiome_nLcaLen_biomeLca.tsv: biome LCB of all the clusters (biome_analysis)
mkdir -p /share/afesm6/39_share_db/pdb_search
awk -F "\t" '$2 >= 10 {print $0}' /share/afesm5/metadata/afesm30-repId_nBiome_nLcaLen_biomeLca.tsv > "${BIOME_CLUSTERS}"

# AFESM biome clusters (non-singletons)
awk 'FNR==NR {id[$1]=1; next} $1 in id {print $0}' "${NONSINGLETON}" "${BIOME_CLUSTERS}" > "${OUT_DIR}/afesm30_biome_specific_nonsingletons-repId_nBiome_nLcaLen_biomeLca.tsv"

# top-level LCB of the clusters (Fig. 2e)
awk '$4=="root" {r++} $4~/.*Environmental.*/ {e++; next;} $4~/.*Engineered.*/ {g++} $4~/.*Host.*/ {h++} END {print "#clusters: "FNR"\nRoot: "r" "r/FNR*100"%\nEnvironmental: "e" "e/FNR*100"%\nEngineered: "g" "g/FNR*100"%\nHost: "h" "h/FNR*100"%"}' "${OUT_DIR}/afesm30_biome_specific_nonsingletons-repId_nBiome_nLcaLen_biomeLca.tsv" > "${OUT_DIR}/specificity_count"
# #clusters: 1414750
# Root: 1275318 90.1444%
# Environmental: 109644 7.75006%
# Engineered: 1128 0.0797314%
# Host: 28660 2.0258%

# kraken-style report of the LCBs (visualized with Pavian)
# automated_krakenReportGen.sh needs id_lineage_correct2.dmp and y_gen_krakenreport4.pl (/share/afesm3/biome_lca_generator) in the working directory
cut -f 4 "${OUT_DIR}/afesm30_biome_specific_nonsingletons-repId_nBiome_nLcaLen_biomeLca.tsv" > "${OUT_DIR}/afesm30_biome_specific_nonsingletons-LCBs"
KRAKEN_REPORT="$(pwd)/biome/automated_krakenReportGen.sh"   # run this file from the repository root
(cd "${OUT_DIR}" && "${KRAKEN_REPORT}" afesm30_biome_specific_nonsingletons-LCBs)

# number of the biome annotations the clusters cover (Fig. 2e)
awk '{n+=$2;} END {print n}' "${OUT_DIR}/afesm30_biome_specific_nonsingletons-repId_nBiome_nLcaLen_biomeLca.tsv" > "${OUT_DIR}/n_biome_annotations" # 238283411

# taxonomic LCA of the extreme biome specific clusters (Fig. 2f-h)
for keyword in Thermal Saline; do
  grep $keyword "${OUT_DIR}/afesm30_biome_specific_nonsingletons-repId_nBiome_nLcaLen_biomeLca.tsv" > "${OUT_DIR}/${keyword}_afesm30_nBiomeGe10-repId_nBiome_nLcaLen_biomeLca.tsv"
  awk 'FNR==NR {id[$1]=1; next} $2 in id {print $0}' "${OUT_DIR}/${keyword}_afesm30_nBiomeGe10-repId_nBiome_nLcaLen_biomeLca.tsv" "${AFESM_DB}.lookup" > "${OUT_DIR}/${keyword}_afesm30_nBiomeGe10.lookup"
  MMSEQS_FORCE_MERGE=1 mmseqs createsubdb "${OUT_DIR}/${keyword}_afesm30_nBiomeGe10.lookup" "${TAX_LCA}" "${OUT_DIR}/${keyword}_afesm30_nBiomeGe10_lca"
  mmseqs taxonomyreport "${AFESM_DB}" "${OUT_DIR}/${keyword}_afesm30_nBiomeGe10_lca" "${OUT_DIR}/${keyword}_afesm30_nBiomeGe10_lca_report"
  mmseqs createtsv "${AFESM_DB}" "${OUT_DIR}/${keyword}_afesm30_nBiomeGe10_lca" "${OUT_DIR}/${keyword}_afesm30_nBiomeGe10_lca.tsv"
done

# taxonomic LCA of the biome specific clusters for the supplementary figures
# Supp. Fig. 2 (Air), 3 (Human digestive system), 4 (Marine); Freshwater is used in Supp. Fig. 5
for keyword in "Human:Digestive" "Air" "Marine" "Freshwater"; do
  grep $keyword "${OUT_DIR}/afesm30_biome_specific_nonsingletons-repId_nBiome_nLcaLen_biomeLca.tsv" > "${OUT_DIR}/${keyword}_afesm30_nBiomeGe10-repId_nBiome_nLcaLen_biomeLca.tsv"
  awk 'FNR==NR {id[$1]=1; next} $2 in id {print $0}' "${OUT_DIR}/${keyword}_afesm30_nBiomeGe10-repId_nBiome_nLcaLen_biomeLca.tsv" "${AFESM_DB}.lookup" > "${OUT_DIR}/${keyword}_afesm30_nBiomeGe10.lookup"
  MMSEQS_FORCE_MERGE=1 mmseqs createsubdb "${OUT_DIR}/${keyword}_afesm30_nBiomeGe10.lookup" "${TAX_LCA}" "${OUT_DIR}/${keyword}_afesm30_nBiomeGe10_lca"
  mmseqs taxonomyreport "${AFESM_DB}" "${OUT_DIR}/${keyword}_afesm30_nBiomeGe10_lca" "${OUT_DIR}/${keyword}_afesm30_nBiomeGe10_lca_report"
  mmseqs createtsv "${AFESM_DB}" "${OUT_DIR}/${keyword}_afesm30_nBiomeGe10_lca" "${OUT_DIR}/${keyword}_afesm30_nBiomeGe10_lca.tsv"
done

# Pfam of the biome specific clusters (gawk: arrays of arrays)
# Pfam annotations of the cluster members: repId, memId, flag, pfams (;-separated), biomeLca
awk 'FNR==NR {id[$1]=1; next} $1 in id {print $0}' "${OUT_DIR}/afesm30_biome_specific_nonsingletons-repId_nBiome_nLcaLen_biomeLca.tsv" /share/afesm5/biome_analysis/afesm30_nBiomeGe10-repId_allMemId_flag_pfam_biomeLca.tsv > "${OUT_DIR}/afesm30_biome_specific_nonsingletons-repId_allMemId_flag_pfam_biomeLca.tsv"
# number of members per Pfam in each cluster
awk -F "\t" '!($1 in id) {id[$1]["_"]=1; biome[$1]=$5;} {N=split($4, arr, ";"); for (i=1; i<=N; i++) { id[$1][arr[i]]++; }} END {for (key in id) {for (pfam in id[key]) {if (pfam=="_") continue; print key"\t"biome[key]"\t"pfam"\t"id[key][pfam]}}}' "${OUT_DIR}/afesm30_biome_specific_nonsingletons-repId_allMemId_flag_pfam_biomeLca.tsv" > "${OUT_DIR}/afesm30_biome_specific_nonsingletons-repId_biomeLca_pfam_cnt.tsv"
# Pfam names
awk -F "\t" 'FNR==NR {id[$1]=$5; next} {print $0"\t"id[$3]}' /share/afesm/pfam/Pfam-A.clans.tsv "${OUT_DIR}/afesm30_biome_specific_nonsingletons-repId_biomeLca_pfam_cnt.tsv" > "${OUT_DIR}/afesm30_biome_specific_nonsingletons-repId_biomeLca_pfam_cnt_pfamName.tsv"

# taxonomic LCA of the biome specific clusters with the most frequent Pfam (Supp. Fig. 5)
# Freshwater: PF18895 (Type IV secretion system pilin), Air: PF12937 (F-box-like), Human digestive system: PF00005 (ABC transporter)
pfam_taxonomy() {
  keyword=$1; pfam=$2; name=$3
  grep "$keyword" "${OUT_DIR}/afesm30_biome_specific_nonsingletons-repId_biomeLca_pfam_cnt_pfamName.tsv" | grep "$pfam" > "${OUT_DIR}/${name}_afesm30_nBiomeGe10_${pfam}_ids"
  awk 'FNR==NR {id[$1]=1; next} $2 in id' "${OUT_DIR}/${name}_afesm30_nBiomeGe10_${pfam}_ids" "${OUT_DIR}/${keyword}_afesm30_nBiomeGe10.lookup" > "${OUT_DIR}/${name}_afesm30_nBiomeGe10_${pfam}.lookup"
  mmseqs createsubdb "${OUT_DIR}/${name}_afesm30_nBiomeGe10_${pfam}.lookup" "${OUT_DIR}/${keyword}_afesm30_nBiomeGe10_lca" "${OUT_DIR}/${name}_afesm30_nBiomeGe10_${pfam}"
  mmseqs taxonomyreport "${AFESM_DB}" "${OUT_DIR}/${name}_afesm30_nBiomeGe10_${pfam}" "${OUT_DIR}/${name}_afesm30_nBiomeGe10_${pfam}_report"
}
pfam_taxonomy "Freshwater" "PF18895" "Freshwater"
pfam_taxonomy "Air" "PF12937" "Air"
pfam_taxonomy "Human:Digestive" "PF00005" "HumanDigestive"

# structural comparison of the biome specific clusters to the non-specific (LCB: root) clusters (Fig. 2i, Supp. Fig. 6)
mkdir -p "${OUT_DIR}/database" "${OUT_DIR}/aln"
# non-specific clusters
foldseek createsubdb <(awk '$4=="root"' "${OUT_DIR}/afesm30_biome_specific_nonsingletons-repId_nBiome_nLcaLen_biomeLca.tsv") "${AFESM_DB}" "${OUT_DIR}/database/afesm30_biome_specific_nonsingletons_root_repseq" --id-mode 1
foldseek createsubdb "${OUT_DIR}/database/afesm30_biome_specific_nonsingletons_root_repseq.index" "${AFESM_DB}_ss" "${OUT_DIR}/database/afesm30_biome_specific_nonsingletons_root_repseq_ss"
foldseek createsubdb "${OUT_DIR}/database/afesm30_biome_specific_nonsingletons_root_repseq.index" "${AFESM_DB}_ca" "${OUT_DIR}/database/afesm30_biome_specific_nonsingletons_root_repseq_ca"
# biome specific clusters
foldseek createsubdb <(awk '$4!="root"' "${OUT_DIR}/afesm30_biome_specific_nonsingletons-repId_nBiome_nLcaLen_biomeLca.tsv") "${AFESM_DB}" "${OUT_DIR}/database/afesm30_biome_specific_nonsingletons_nonroot_repseq" --id-mode 1
foldseek createsubdb "${OUT_DIR}/database/afesm30_biome_specific_nonsingletons_nonroot_repseq.index" "${AFESM_DB}_ss" "${OUT_DIR}/database/afesm30_biome_specific_nonsingletons_nonroot_repseq_ss"
foldseek createsubdb "${OUT_DIR}/database/afesm30_biome_specific_nonsingletons_nonroot_repseq.index" "${AFESM_DB}_ca" "${OUT_DIR}/database/afesm30_biome_specific_nonsingletons_nonroot_repseq_ca"

foldseek search "${OUT_DIR}/database/afesm30_biome_specific_nonsingletons_nonroot_repseq" "${OUT_DIR}/database/afesm30_biome_specific_nonsingletons_root_repseq" "${OUT_DIR}/aln/root_nonroot_aln" /mnt/scratch/tmp -a
foldseek convertalis "${OUT_DIR}/database/afesm30_biome_specific_nonsingletons_nonroot_repseq" "${OUT_DIR}/database/afesm30_biome_specific_nonsingletons_root_repseq" "${OUT_DIR}/aln/root_nonroot_aln" "${OUT_DIR}/aln/root_nonroot_aln_res" --format-output query,target,qcov,tcov,fident,alnlen,mismatch,gapopen,qstart,qend,tstart,tend,evalue,bits,lddt,qtmscore,alntmscore
