#!/usr/bin/env bash
# Supp. Fig. 11: FastRelax of the 45 novel fold models (12 ESMFold, 33 AF2-ColabFold)
# Plotted by plot_novel_fold_fastrelax.py
set -euo pipefail

TAX_DIR="/share/afesm6/49_tax_of_novel"
NOVEL_DIR="/share/afesm6/50_novel_struct_dl"
OUT_DIR="/share/afesm6/52_fastrelax"
# AF2-ColabFold models of the abandoned domains (prediction/abandoned_domains)
COLABFOLD_FOLDCOMP="/fast/esmfold/abandoned_preds/database/pdb_final_comp"
# ESMatlas structures of AFESM
AFESM_FOLDCOMP="/share/afesm/database/afesm_foldcomp"
mkdir -p "${NOVEL_DIR}/database" "${OUT_DIR}/database/pdbs" "${OUT_DIR}/database/pdbs_fastrelax" "${OUT_DIR}/aln"

# 33 AF2-ColabFold novel folds (novel_from_bins: novel fold list)
awk 'FNR==NR {id[$1]=1; next} {N=split($2, arr, "_"); l=arr[1]"_"arr[2]; if (l in id) print $2}' "${TAX_DIR}/novel_from_bins" "${COLABFOLD_FOLDCOMP}.lookup" > "${NOVEL_DIR}/novel_domain_lookup_from_bins"
foldcomp decompress -t 128 --id-list "${NOVEL_DIR}/novel_domain_lookup_from_bins" "${COLABFOLD_FOLDCOMP}" "${NOVEL_DIR}/database/abandoned_colab_pdbs/"

# 12 ESMFold novel folds, chopped out of their ESMatlas structures
# novel_from_pipeline2: novel fold list with the domain boundaries (domainId, start-end[_start-end])
# novel_domain_ids: novel_fold_cluster_commands.sh
foldcomp decompress -l "${NOVEL_DIR}/novel_domain_ids" "${AFESM_FOLDCOMP}" "${NOVEL_DIR}/database/novel_domain_pdbs" -t 32
awk '{
    n=split($1,a,"_"); base=a[1]; for(i=2;i<n;i++) base=base"_"a[i];
    m=split($2,r,"_"); out="";
    for(i=1;i<=m;i++) {
        split(r[i],pos,"-");
        if(out=="") out=pos[1]","pos[2]","$1;
        else out=out","pos[1]","pos[2]","$1;
    }
    print base"\t"out
}' "${TAX_DIR}/novel_from_pipeline2" > "${NOVEL_DIR}/novel_domain_pipeline.tsv"
cat "${TAX_DIR}/novel_from_bins" "${TAX_DIR}/novel_from_pipeline2" > "${NOVEL_DIR}/novel_domain"
python3 novel_fold_analyses/chop_pdb_by_domain.py "${NOVEL_DIR}/database/novel_domain_pdbs/" "${NOVEL_DIR}/novel_domain" "${NOVEL_DIR}/database/novel_domain_pdbs_chopped"

# input of FastRelax: all 33 ColabFold models + the 12 chopped ESMFold models
for f in "${NOVEL_DIR}/database/abandoned_colab_pdbs"/*.pdb; do
    ln -sf "$(readlink -f "$f")" "${OUT_DIR}/database/pdbs/"
done
declare -A pipe
while IFS=$'\t' read -r ent rest; do
    [ -n "$ent" ] && pipe["$ent"]=1
done < "${NOVEL_DIR}/novel_domain_pipeline.tsv"
for f in "${NOVEL_DIR}/database/novel_domain_pdbs_chopped"/*.pdb; do
    ent=$(basename "$f" | grep -oE '^MGYP[0-9]+')
    if [ -n "${pipe[$ent]:-}" ]; then ln -sf "$(readlink -f "$f")" "${OUT_DIR}/database/pdbs/"; fi
done

# FastRelax -> /share/afesm6/52_fastrelax/output/ (relaxed PDBs, fastrelax_summary.tsv with Cα-RMSD)
python novel_fold_analyses/novel_fold_fastrelax.py

# align each input model (query) to its relaxed model (target): lDDT, qTM-score
foldseek createdb "${OUT_DIR}/database/pdbs" "${OUT_DIR}/database/novel_domains_db"
ln -sr "${OUT_DIR}"/output/*.pdb "${OUT_DIR}/database/pdbs_fastrelax/"
foldseek createdb "${OUT_DIR}/database/pdbs_fastrelax/" "${OUT_DIR}/database/novel_domains_relax_db"
# both databases are in the same name order, so the n-th entries are paired
paste <(cut -f1 "${OUT_DIR}/database/novel_domains_db.lookup") <(cut -f1 "${OUT_DIR}/database/novel_domains_relax_db.lookup") > "${OUT_DIR}/aln/match.tsv"
foldseek tsv2db "${OUT_DIR}/aln/match.tsv" "${OUT_DIR}/aln/match_db" --output-dbtype 7
foldseek structurealign "${OUT_DIR}/database/novel_domains_db" "${OUT_DIR}/database/novel_domains_relax_db" "${OUT_DIR}/aln/match_db" "${OUT_DIR}/aln/aln_db" --tmscore-threshold 0.0 -e inf -a
foldseek convertalis "${OUT_DIR}/database/novel_domains_db" "${OUT_DIR}/database/novel_domains_relax_db" "${OUT_DIR}/aln/aln_db" "${OUT_DIR}/aln/result.tsv" --format-output "query,target,lddt,qtmscore,alntmscore,rmsd"
