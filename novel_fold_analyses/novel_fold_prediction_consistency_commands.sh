#!/usr/bin/env bash
# Supp. Fig. 12: prediction consistency of the 45 novel folds (12 ESMFold, 33 AF2-ColabFold)
# ColabFold rank_001-005 models, ESMFold2 models, their alignments and pLDDT
# Plotted by plot_novel_fold_prediction_consistency.py
set -euo pipefail

NOVEL_DIR="/share/afesm6/50_novel_struct_dl"
OUT_DIR="/share/afesm6/51_5model"
mkdir -p "${OUT_DIR}/database" "${OUT_DIR}/compare_esmFold" "${OUT_DIR}/esmfold2/database" "${OUT_DIR}/esmfold2/alignment" "${OUT_DIR}/plddt"

# novel fold models (novel_fold_fastrelax_commands.sh)
#   abandoned_colab_pdbs: 33 AF2-ColabFold novel folds
#   novel_domain_pdbs_chopped: novel folds chopped out of their ESMatlas structures
# pred_pdbs_db: AF2-ColabFold rank_001 models of the 12 full-length proteins with the ESMFold novel folds
foldseek createdb "${NOVEL_DIR}/database/novel_domain_pdbs_chopped" "${NOVEL_DIR}/database/novel_domain_pdbs_chopped_db"
foldseek createdb "${NOVEL_DIR}/database/abandoned_colab_pdbs/" "${NOVEL_DIR}/database/abandoned_colab_pdbs_db"
foldseek concatdbs "${NOVEL_DIR}/database/abandoned_colab_pdbs_db" "${NOVEL_DIR}/database/pred_pdbs_db" "${NOVEL_DIR}/database/novel_domain_colabs_db"

# ColabFold 5 models of the 33 rescued novel folds (MSA: MMseqs2 15.6f452)
mmseqs convert2fasta "${NOVEL_DIR}/database/novel_domain_colabs_db" "${NOVEL_DIR}/database/novel_domain_45.fasta"
sbatch novel_fold_analyses/colabfold_search_msa.sh "${NOVEL_DIR}/database/novel_domain_45.fasta" "${NOVEL_DIR}/database/msa_novel_domain_155"
sbatch novel_fold_analyses/colabfold_predict_5models.sh "${NOVEL_DIR}/database/msa_novel_domain_155" "${NOVEL_DIR}/output_5model"

# ColabFold 5 models of the 12 ESMFold novel folds, predicted from the chopped domain sequences
awk 'NR==FNR{if(FNR>33){split($2,a,"_"); ids[a[1]]}; next} {split($2,b,"_"); if(b[1] in ids) print}' "${NOVEL_DIR}/database/novel_domain_colabs_db.lookup" "${NOVEL_DIR}/database/novel_domain_pdbs_chopped_db.lookup" > "${NOVEL_DIR}/database/novel_domain_pdbs_chopped_pipeline_ids"
mmseqs createsubdb "${NOVEL_DIR}/database/novel_domain_pdbs_chopped_pipeline_ids" "${NOVEL_DIR}/database/novel_domain_pdbs_chopped_db" "${NOVEL_DIR}/database/novel_domain_pdbs_chopped_pipeline_db"
mmseqs convert2fasta "${NOVEL_DIR}/database/novel_domain_pdbs_chopped_pipeline_db" "${NOVEL_DIR}/database/novel_domain_pdbs_chopped_pipeline_db.fasta"
sbatch novel_fold_analyses/colabfold_search_msa.sh "${NOVEL_DIR}/database/novel_domain_pdbs_chopped_pipeline_db.fasta" "${NOVEL_DIR}/database/msa_novel_domain_pipeline"
# TODO: the prediction of msa_novel_domain_pipeline -> ${NOVEL_DIR}/output_5model_pipeline is not in the log

# (run the following after the ColabFold jobs are finished)
# collect the 5 models as <domainId>_rank_00N.pdb (the 12 ESMFold folds from output_5model_pipeline)
mkdir -p "${NOVEL_DIR}/output_5model_concat"
link_clean() {
    local f="$1" b did rk
    b=$(basename "$f")
    did=$(echo "$b" | grep -oE '^MGYP[0-9]+_[0-9]+' || true)
    rk=$(echo "$b" | grep -oE 'rank_00[1-5]' | tail -1)
    if [ -z "$did" ] || [ -z "$rk" ]; then return; fi
    ln -sf "$(readlink -f "$f")" "${NOVEL_DIR}/output_5model_concat/${did}_${rk}.pdb"
}
declare -A seen
for f in "${NOVEL_DIR}/output_5model_pipeline"/*_seed_[0-9][0-9][0-9].pdb; do
    [ -e "$f" ] || continue
    link_clean "$f"
    ent=$(basename "$f" | grep -oE '^MGYP[0-9]+' || true)
    if [ -n "$ent" ]; then seen["$ent"]=1; fi
done
for f in "${NOVEL_DIR}/output_5model"/*_seed_[0-9][0-9][0-9].pdb; do
    [ -e "$f" ] || continue
    ent=$(basename "$f" | grep -oE '^MGYP[0-9]+' || true)
    if [ -z "${seen[$ent]:-}" ]; then link_clean "$f"; fi
done

# rescued folds: ColabFold rank_001 vs rank_001-005
foldseek createdb "${NOVEL_DIR}/output_5model_concat" "${OUT_DIR}/database/novel_domain_colabfold_db"
LK="${OUT_DIR}/database/novel_domain_colabfold_db.lookup"; awk -F'\t' '{did=$2; sub(/_rank_00[0-9]+\.pdb$/,"",did); grp[did]=grp[did]" "$1; if($2 ~ /_rank_001\.pdb$/) rep[did]=$1} END{for(d in grp){r=rep[d]; if(r==""){split(grp[d],a," "); r=a[1]} n=split(grp[d],m," "); for(i=1;i<=n;i++) if(m[i]!="") print r"\t"m[i]}}' "$LK" > "${OUT_DIR}/database/novel_domain_colabfold_clu.tsv"
foldseek tsv2db "${OUT_DIR}/database/novel_domain_colabfold_clu.tsv" "${OUT_DIR}/database/novel_domain_colabfold_clu" --output-dbtype 6
foldseek structurealign "${OUT_DIR}/database/novel_domain_colabfold_db" "${OUT_DIR}/database/novel_domain_colabfold_db" "${OUT_DIR}/database/novel_domain_colabfold_clu" "${OUT_DIR}/database/novel_domain_colabfold_aln" -a -e inf
foldseek convertalis "${OUT_DIR}/database/novel_domain_colabfold_db" "${OUT_DIR}/database/novel_domain_colabfold_db" "${OUT_DIR}/database/novel_domain_colabfold_aln" "${OUT_DIR}/database/novel_domain_colabfold.tsv" --format-output query,target,lddt,qtmscore,alntmscore,evalue

# ESMFold folds: ESMFold model vs ColabFold rank_001-005
foldseek concatdbs "${OUT_DIR}/database/novel_domain_colabfold_db" "${NOVEL_DIR}/database/novel_domain_pdbs_chopped_db" "${OUT_DIR}/compare_esmFold/novel_concat_db"
awk 'BEGIN{OFS="\t"} NR==FNR{id[$2]=$1; next} {split($2,a,"_rank_"); base=a[1]".pdb"; print id[base], id[$2]}' "${OUT_DIR}/compare_esmFold/novel_concat_db.lookup" "${OUT_DIR}/database/novel_domain_colabfold_db.lookup" > "${OUT_DIR}/compare_esmFold/novel_concat_db_clu.tsv"
foldseek tsv2db "${OUT_DIR}/compare_esmFold/novel_concat_db_clu.tsv" "${OUT_DIR}/compare_esmFold/novel_concat_db_clu" --output-dbtype 6
foldseek structurealign "${OUT_DIR}/compare_esmFold/novel_concat_db" "${OUT_DIR}/compare_esmFold/novel_concat_db" "${OUT_DIR}/compare_esmFold/novel_concat_db_clu" "${OUT_DIR}/compare_esmFold/novel_concat_db_aln" -a -e inf
foldseek convertalis "${OUT_DIR}/compare_esmFold/novel_concat_db" "${OUT_DIR}/compare_esmFold/novel_concat_db" "${OUT_DIR}/compare_esmFold/novel_concat_db_aln" "${OUT_DIR}/compare_esmFold/novel_concat_db_aln.tsv" --format-output query,target,lddt,qtmscore

# ESMFold folds: ESMFold model vs ESMFold2 model
# esmfold2/pdb: ESMFold2 web server predictions (esmfold2-2026-05, 10 loops, 100 sampling steps) of the 12 ESMFold novel folds
awk 'NR==FNR{e[$1];next} {id=$2; sub(/_[0-9]+\.pdb$/,"",id); if(id in e) print $1}' "${NOVEL_DIR}/novel_domain_pipeline.tsv" "${NOVEL_DIR}/database/novel_domain_pdbs_chopped_db.lookup" > "${OUT_DIR}/esmfold2/database/pipeline_ids.txt"
foldseek createsubdb "${OUT_DIR}/esmfold2/database/pipeline_ids.txt" "${NOVEL_DIR}/database/novel_domain_pdbs_chopped_db" "${OUT_DIR}/esmfold2/database/novel_domain_esmfold" --subdb-mode 1
foldseek createdb "${OUT_DIR}/esmfold2/pdb" "${OUT_DIR}/esmfold2/database/esmfold2"
awk 'NR==FNR{id=$2; sub(/\.[a-z]+$/,"",id); q[id]=$1; next} {id=$2; sub(/\.[a-z]+$/,"",id); if(id in q) print q[id]"\t"$1}' "${OUT_DIR}/esmfold2/database/novel_domain_esmfold.lookup" "${OUT_DIR}/esmfold2/database/esmfold2.lookup" > "${OUT_DIR}/esmfold2/alignment/pairs.tsv"
foldseek tsv2db "${OUT_DIR}/esmfold2/alignment/pairs.tsv" "${OUT_DIR}/esmfold2/alignment/pairs_db" --output-dbtype 5
foldseek structurealign "${OUT_DIR}/esmfold2/database/novel_domain_esmfold" "${OUT_DIR}/esmfold2/database/esmfold2" "${OUT_DIR}/esmfold2/alignment/pairs_db" "${OUT_DIR}/esmfold2/alignment/aln" -a -e inf
foldseek convertalis "${OUT_DIR}/esmfold2/database/novel_domain_esmfold" "${OUT_DIR}/esmfold2/database/esmfold2" "${OUT_DIR}/esmfold2/alignment/aln" "${OUT_DIR}/esmfold2/alignment/esmfold2_aln.tsv" --format-output query,target,lddt,qtmscore,alntmscore

# domain pLDDT of the ESMFold2, ESMFold and ColabFold models
# novel_domain: novel_fold_fastrelax_commands.sh
python3 novel_fold_analyses/novel_fold_domain_plddt.py "${NOVEL_DIR}/novel_domain" "${OUT_DIR}/esmfold2/pdb/" "${OUT_DIR}/plddt/esmfold2-domain_plddt.tsv"
python3 novel_fold_analyses/novel_fold_domain_plddt.py "${NOVEL_DIR}/novel_domain" "${NOVEL_DIR}/database/novel_domain_pdbs_chopped" "${OUT_DIR}/plddt/esmfold-domain_plddt.tsv"
python3 novel_fold_analyses/novel_fold_domain_plddt.py "${NOVEL_DIR}/novel_domain" "${NOVEL_DIR}/output_5model_concat" "${OUT_DIR}/plddt/colabfold-domain_plddt.tsv"
