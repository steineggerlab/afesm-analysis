# AFESM Analysis

Analysis workflows for the AFESM database - AFDB (AlphaFold Database) and ESMatlas (ESM metagenomic atlas).

## Overview

This repository contains a multi-stage pipeline that:

1. Prepares the AFDB and the ESMatlas, concates and clusters the database
2. Predicts the taxonomy distribution and identifies the unique structures in specific environmental biomes
3. Predicts and filters protein domain boundaries from AFESM
4. Classifies domains against the CATH structural database to identify novel folds
5. Analyzes multi-domain protein architectures for enriched/depleted domain combinations
6. sampling 10,000 entries from the low quality structures to repredict with ColabFold


```
AFDB / ESMatlas
         │
         ▼
  Concatenation & Clustering
         │
         ▼
  Taxonomy assignment
  (LCA per taxonomic rank)
         │
         ▼
  Biome classification
  (MGnify biome mapping)
         │
         ▼
  CATH domain classification
  → CATH match (known fold)
  → No CATH match (novel fold candidate)
         │
         ▼
  Remodelling low-quality structures
  (10k sampling → ColabFold reprediction)
         │
         ▼
  Multi-domain combination analysis
  (statistical enrichment / depletion)
```

## Directory Structure

```
afesm-analysis/
├── concate_clustering/           # Concatenation and clustering of AFDB & ESMatlas
│   ├── before_clustering/        # Metadata distribution of AFDB, ESMatlas and AFESM (Fig. 1a)
│   └── after_clustering/         # Cluster quality and projected metadata (Fig. 2a, Fig. 2 metadata)
├── taxonomy/                     # Assignment of taxonomy
├── biome/                        # Environmental biome context analysis
│   └── mdp_biome_enrichment/     # LCB enrichment for novel MDPs (Supp. Table 5)
├── prediction/                   # Domain boundary prediction and pLDDT comparison
│   ├── abandoned_domains/        # AF2-ColabFold re-prediction of the 2.3M low-quality domains (Supp. Fig. 9a, 9e)
│   └── rescued_vs_unrescued/     # AF2-ColabFold rescue quality analysis (Supp. Fig. 9b-d)
├── novel_fold_analyses/          # Core novel domain discovery, quality filtering and the 45 novel folds
├── multidomain_analysis/         # Multi-domain protein architecture analysis
│   └── mdp_artefact_check/       # Novel vs Non-novel MDP comparison (Supp. Fig. 14)
└── analysis_10k_subset_sampling/ # 10k sampling for ColabFold reprediction
```

### File paths

The scripts use the absolute paths of the analysis server with the user directories removed, for example:

| Path | Content |
|------|---------|
| `/fast/esmfold/databases/afesm` | AFESM (AFDB + ESMatlas) Foldseek/MMseqs2 database |
| `/share/afesm5/` | Cluster TSVs, member annotations and metadata of the AFESM clusters |
| `/share/afesm6/` | Final analysis directory (one numbered subdirectory per analysis, e.g. `43_biome_nonsingleton/`) |
| `/fast/databases/...` | Public databases (AFDB, PDB, ...) |

Adjust these paths to your environment before running the scripts.

## Modules

### `concate_clustering/`

Concatenates AFDB and ESMatlas entries and clusters them for downstream analysis.

**Key files:**
- `concatenation` — Concatenation, MMseqs2 sequence clustering, representative selection (pLDDT ≥ 60), Foldseek structure clustering and cluster reassignment (`--cluster-reassign 1`)
- `before_clustering/metadata_distribution_commands.sh`, `plot_metadata_distribution_afesm.py` — Pfam, fragment, taxonomy and biome annotations of AFDB and ESMatlas (Fig. 1a)
- `after_clustering/cluster_quality_commands.sh`, `plot_cluster_quality.py` — Average member-to-representative lDDT and TM-score of the non-singleton clusters (Fig. 2a)
- `after_clustering/nonsingleton_metadata_distribution_commands.sh`, `plot_metadata_distribution_nonsingleton.py` — Annotations of the non-singleton cluster members after projection of labels (Fig. 2)

### `taxonomy/`

Assigns taxonomic labels to ESMatlas, converts the AFDB labels to GTDB, and computes the LCA of the AFESM clusters.

**Key files:**
- `taxonomy_preparation` — GTDB + UniRef90 reference database, ESMatlas taxonomy prediction, NCBI-to-GTDB conversion of AFDB
- `tax_rank_grouping.py` — Groups every taxId into the rank groups used in the figures (root, cellular organism, superkingdom, ...) and maps it to its superkingdom
- `esmatlas_tax_prediction_count_commands.sh`, `15_tax_plain_bar.ipynb` — Rank groups of the predicted ESMatlas taxonomy (Fig. 2b)
- `taxonomy_lca`, `15_tax_LCA.ipynb` — Lowest Common Ancestor (LCA) of the non-singleton clusters (Fig. 2c, Supp. Fig. 1)

### `biome/`

Links AFESM clusters to environmental contexts via MGnify biome classifications.

**Biome categories analyzed:** Thermal Spring, Non-marine Saline and Alkaline, Freshwater, Human Digestive System, Air, Marine

**Key files:**
- `new_LCA_ignoreMixed.cpp` — C++ LCB (Lowest Common Biome) computation ignoring the `mixed` label
- `biome_analysis` — Maps proteins to biomes; computes the LCB of every cluster
- `43_biome_nonsingleton_commands.sh` — Selects the 1.41M AFESM biome clusters (non-singleton, ≥10 biome annotations); biome specificity (Fig. 2e), taxonomy of the biome-specific clusters (Fig. 2f–h, Supp. Figs. 2–5), and Foldseek search against the non-specific clusters (Fig. 2i, Supp. Fig. 6)
- `43_biome_dist.ipynb` — Biome annotation coverage and LCB distribution of the AFESM biome clusters (Fig. 2e)
- `43_superkingdom_summary.ipynb` — Superkingdom distributions of the Thermal Spring and Saline specific clusters (Fig. 2f–h)

**`mdp_biome_enrichment/`** — Computes LCB assignment rates for novel vs non-novel MDPs (Supplementary Table 5). Shows that the enrichment (57.5% vs 42.2%) is driven by cluster membership size (133 vs 65 average members) rather than intrinsic biome differences.

### `prediction/`

Compares structure predictions from AFDB and ESMFold and extracts per-domain pLDDT metrics.

**Subdirectories:**
- `TED_novel_domains/` — Notebooks and scripts comparing AlphaFold vs ESMFold pLDDT for ~7,415 TED novel domains; identifies ~1,948 domains lacking cross-method alignment (Supp. Fig. 9f)
- `abandoned_domains/` — AF2-ColabFold re-prediction of the 2.3M domains with no CATH hit discarded due to low quality
  - `analysis/abandoned_plddt_comp_commands.sh`, `abandoned_plddt_comp.ipynb` — ESMFold vs AF2-ColabFold pLDDT of the re-predicted domains (Supp. Fig. 9a)
  - `analysis/rescued_domain_alignment_commands.sh`, `abandoned_domain_colabfold_plddt.py`, `plot_rescued_domain_alignment.py` — Structural similarity between the rescued domains and their ESMatlas counterparts (Supp. Fig. 9e)
- `rescued_vs_unrescued/` — Compares 1,000 AF2-ColabFold rescued vs 1,000 unrescued domains from the 2.3M low-quality pool by IUPred3 disorder, Neff, and domain length (Supplementary Figure 9b-d)

**Key scripts:**
- `AFDB_ESM_complete.ipynb` — Density plot comparison of AFDB vs ESMFold confidence scores
- `19_plddt.py` — Extract per-residue pLDDT from PDB ATOM records; output TSV
- `19_makefile_s2e.sh`, `19_chop_domain_s2e.py` — Chop domains out of a Foldseek database by their start/end positions
- `esmfold_bulk_argv_size_constraint.py` — Batch ESMFold inference with memory management

### `novel_fold_analyses/`

Filters and characterizes domains with no CATH structural match (novel folds).

**Key scripts:**
- `parse_newfolds.py` / `parse_alldoms.py` — Parse alignment outputs and filter by quality thresholds (qtmscores > 0.56, query/target coverage > 0.6)
- `filter_domains.py` — Remove low-quality fragments (min domain size: 25 residues, min fragment: 5 residues)
- `compare_choppings.py` — Compare domain boundary predictions from multiple tools (Merizo, Chainsaw, UniDoc, CRH) and generate consensus assignments
- `chopping_to_pdb.py` — Embed domain IDs into PDB occupancy columns for downstream visualization
- `calculate_top80_mean_plddt.py` — Compute mean and top-80% mean pLDDT per domain
- `plot_data_metagenome.py` — Generate 9-panel summary figure (pLDDT distributions, secondary structure, globularity, domain classification, packing density)

**The 45 novel folds (12 ESMFold, 33 AF2-ColabFold):**
- `novel_fold_cluster_commands.sh`, `plot_novel_fold_cluster_metadata.py` — Metadata and taxonomic LCA of the clusters with the novel folds (Supp. Fig. 10)
- `novel_fold_fastrelax_commands.sh`, `novel_fold_fastrelax.py`, `plot_novel_fold_fastrelax.py` — Structural stability after Rosetta FastRelax (Supp. Fig. 11)
- `novel_fold_prediction_consistency_commands.sh`, `novel_fold_domain_plddt.py`, `plot_novel_fold_prediction_consistency.py` — Consistency with the AF2-ColabFold rank_001–005 and ESMFold2 models (Supp. Fig. 12)
- `colabfold_search_msa.sh`, `colabfold_predict_5models.sh` — SLURM scripts for the MSA generation and the 5-model AF2-ColabFold prediction of the novel folds
- `chop_pdb_by_domain.py` — Chop the novel fold domains out of their full-length structures
- `esm_only_cluster_composition.ipynb` — Composition of the ESM-only cluster representatives (Supp. Fig. 16)

### `analysis_10k_subset_sampling/`

Produces balanced 10,000-entry subsets of low-quality structures for reprediction with ColabFold.

- Samples from singleton proteins and low-pLDDT representatives
- Restricts to MGYP metagenomic sequences

### `multidomain_analysis/`

Identifies novel multi-domain combinations and tests for statistical over/under-representation.

**Subdirectories:**

`extract_novel_combination/` — Shell pipeline (steps 0–7):
| Step | Script | Purpose |
|------|--------|---------|
| 0 | `0_extract_fields_AF/ESM.sh` | Extract domain and pLDDT fields |
| 1 | `1_concatCATH.sh` | Concatenate CATH domain codes |
| 2 | `2_remove_Hlevel.sh` | Retain Topology (T) level only, drop Homology (H) |
| 3 | `3_remove_redundancy_and_sort.sh` | Deduplicate topology combinations |
| 4 | `4_gen_copairs.sh` | Generate domain co-occurrence pairs |
| 5 | `5_compare_copairs_set.sh` | Compare pair sets between methods |
| 6–7 | `6_concatCATHpairs.sh`, `7_mapping_CATHnames.sh` | Map CATH codes to readable names |

`novel_combination_CATH_over_underrepresentation/` — Statistical enrichment:
- `chi-fisher_test.R` — Chi-square / Fisher's exact tests
- `log2foldRatio_log10p-val.sh` — Log2 fold enrichment and -log10(p-value)
- `count_novel_notNovel.sh` — Compare novel vs known combination counts

`mdp_artefact_check/` — Architecture-level comparison of Novel (n=5,203) vs Non-novel (n=134,576) H-level MDPs (Supplementary Figure 14). Tests whether unexpected domain pairings can be explained by fragmentation artefacts by comparing domain count, CATH-annotation fraction, and mean domain length per MDP.

`visualization/` — Jupyter notebooks and table generators for main and supplementary publication figures, including DeepFRI GO annotation table (Supplementary Table 2) and biome LCB distribution table (Supplementary Table 5). The notebook names follow an earlier figure numbering:

| Notebook | Figure in the manuscript |
|----------|--------------------------|
| `Main_fig6_ab.ipynb` | Fig. 4a–b |
| `Main_fig6_c.ipynb` | Fig. 4c |
| `Main_fig6_d.ipynb` | Fig. 4d |
| `Supple_fig_12.ipynb` | Supp. Fig. 15 |
| `Supple_table_1_2.ipynb` | Supp. Tables 3–4 |

## Key Quality Thresholds

| Parameter | Threshold | Description |
|-----------|-----------|-------------|
| qtmscores | > 0.56 | Alignment TM-score confidence |
| qcov / tcov | > 0.6 | Query / target coverage |
| Min domain size | 25 residues | Exclude very short domains |
| Min fragment size | 5 residues | Minimum fragment to retain |

## Dependencies

- Python (NumPy, Pandas, Matplotlib, Seaborn, Biopython, foldcomp, PyRosetta for FastRelax)
- R (statistical testing)
- C++ (LCA computation)
- Shell (AWK/gawk, Bash pipeline orchestration)
- Snakemake (workflow management, optional)
- External tools: Foldseek, MMseqs2, Foldcomp, ColabFold, Merizo, Chainsaw, UniDoc, CRH
