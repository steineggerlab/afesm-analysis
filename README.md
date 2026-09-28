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
├── taxonomy/                     # Assignment of taxonomy
├── biome/                        # Environmental biome context analysis
│   └── mdp_biome_enrichment/     # LCB enrichment for novel MDPs (Supp. Table 5)
├── prediction/                   # Domain boundary prediction and pLDDT comparison
│   └── rescued_vs_unrescued/     # AF2-ColabFold rescue quality analysis (Supp. Fig. 9b-d)
├── novel_fold_analyses/          # Core novel domain discovery and quality filtering
├── multidomain_analysis/         # Multi-domain protein architecture analysis
│   └── mdp_artefact_check/       # Novel vs Non-novel MDP comparison (Supp. Fig. 14)
└── analysis_10k_subset_sampling/ # 10k sampling for ColabFold reprediction
```

## Modules

### `concate_clustering/`

Concatenates AFDB and ESMatlas entries and clusters them for downstream analysis.

### `taxonomy/`

Maps novel domains to NCBI taxonomy and analyzes their evolutionary distribution.

**Key analyses:**
- `15_tax_LCA.ipynb` — Lowest Common Ancestor (LCA) analysis

### `biome/`

Links novel domains to environmental contexts via MGnify biome classifications.

**Biome categories analyzed:** Human Digestive, Human Skin, Plant, Air, Soil, Wastewater, Marine, Aquatic, Food, Salt, Engineered/Lab

**Key files:**
- `new_LCA_ignoreMixed.cpp` — C++ LCB (Lowest Common Biome) computation ignoring the `mixed` label
- `biome_analysis` — Maps proteins to biomes; generates biome-specific LCB profiles
- `30_superkingdom_summary.ipynb` — Superkingdom distributions stratified by biome

**`mdp_biome_enrichment/`** — Computes LCB assignment rates for novel vs non-novel MDPs (Supplementary Table 5). Shows that the enrichment (57.5% vs 42.2%) is driven by cluster membership size (133 vs 65 average members) rather than intrinsic biome differences.

### `prediction/`

Compares structure predictions from AFDB and ESMFold and extracts per-domain pLDDT metrics.

**Subdirectories:**
- `TED_novel_domains/` — Notebooks and scripts comparing AlphaFold vs ESMFold pLDDT for ~7,415 TED novel domains; identifies ~1,948 domains lacking cross-method alignment
- `abandoned_domains/` — Analysis of domains initially predicted but later excluded from the main dataset
- `rescued_vs_unrescued/` — Compares 1,000 AF2-ColabFold rescued vs 1,000 unrescued domains from the 2.3M low-quality pool by IUPred3 disorder, Neff, and domain length (Supplementary Figure 9b-d)

**Key scripts:**
- `AFDB_ESM_complete.ipynb` — Density plot comparison of AFDB vs ESMFold confidence scores
- `19_plddt.py` — Extract per-residue pLDDT from PDB ATOM records; output TSV
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

`visualization/` — Jupyter notebooks and table generators for main and supplementary publication figures, including DeepFRI GO annotation table (Supplementary Table 2) and biome LCB distribution table (Supplementary Table 5).

## Key Quality Thresholds

| Parameter | Threshold | Description |
|-----------|-----------|-------------|
| qtmscores | > 0.56 | Alignment TM-score confidence |
| qcov / tcov | > 0.6 | Query / target coverage |
| Min domain size | 25 residues | Exclude very short domains |
| Min fragment size | 5 residues | Minimum fragment to retain |

## Dependencies

- Python (NumPy, Pandas, Matplotlib, Seaborn, Biopython)
- R (statistical testing)
- C++ (LCA computation)
- Shell (AWK, Bash pipeline orchestration)
- Snakemake (workflow management, optional)
- External tools: Foldseek, MMseqs2, Merizo, Chainsaw, UniDoc, CRH
