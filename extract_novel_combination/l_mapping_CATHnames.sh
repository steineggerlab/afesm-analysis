#!/bin/bash

 

# CATH name 부터 붙이기; 
# 피겨 c, d, e 만들기 

 
awk '{gsub(/ /, "_"); print}' ../data/CATH_metadat/cath-names.txt | \
awk '{gsub(/____/, "\t"); print}' | \
awk -F"\t" -v OFS='\t' '{$3 = substr($3, 2); print}' > ../data/CATH_metadat/cath-names_modified.txt   # 새로 다운받아서 가공하기? 

awk -F"\t" -v OFS='\t' '$3=="" {print $1, $2, "no_name"}' ../data/CATH_metadat/cath-names_modified.txt  > ../data/CATH_metadat/cath-names_modified2.txt  # 해결하기 

#
awk -F'\t' -v OFS='\t'  '
    NR == FNR {
        # Read the first file and store field3 with field1 as the key
        mapping[$1] = $3
        next
    }
    {
        # Split field3 of the second file by semicolons
        n = split($3, keys, ";")
        values = ""
        # Loop over each key to build the corresponding values string
        for (i = 1; i <= n; i++) {
            key = keys[i]
            if (values != "")
                values = values " & "
            values = values mapping[key]
        }
        # Print the original line with the new mapped values appended
        print $1 "\t" $3 "\t" values
    }
' ../data/CATH_metadat/cath-names_modified.txt \
    ../data/ESM-only/HlevelCombi_mapped/1_extract-H_concat-RESULT-sorted-multi-ID_Hcombi_Hpair_Tpairs-sortedTpairs-NOVEL.tsv  \
  > ../data/ESM-only/HlevelCombi_mapped/1_extract-H_concat-RESULT-sorted-NOVEL-multi-ID_Hpairs_CATHpair.tsv








# membrane domain 

awk -F'\t' -v OFS='\t' '{
    desc = tolower($4);  # Convert field 4 to lowercase
    gsub("_", " ", desc);  # Replace underscores with spaces for keyword matching
    if (desc ~ /periplasmic/ || desc ~ /receptor/ || desc ~ /channel/ || desc ~ /transport/)
        print $0 
}' ../data/cath-superfamily_modified.txt | sort | uniq > ../data/cath-superfamily_modified-MEMB.tsv



#
# 2.170.130;3.40.190      8       4547    Ferric_Hydroxamate_Uptake_Protein;_Chain_A,_domain_1 & D-Maltodextrin-Binding_Protein;_domain_2
# 1.20.1640;3.20.20;3.30.2090     5       1953    Multidrug_efflux_transporter_AcrB_transmembrane_fold & TIM_Barrel & Multidrug_efflux_transporter_AcrB_TolC_docking_domain;_DN_and_DC_subdomains_
# 2.60.40;3.40.920        5       476     Immunoglobulin-like & Pyruvate-ferredoxin_Oxidoreductase;_domain_3
# 3.20.20;3.30.2090       5       114     TIM_Barrel & Multidrug_efflux_transporter_AcrB_TolC_docking_domain;_DN_and_DC_subdomains_
# 3.30.365;3.90.550       4       776     Aldehyde_Oxidoreductase;_domain_4 & Spore_Coat_Polysaccharide_Biosynthesis_Protein_SpsA;_Chain_A
# 3.10.310;3.90.226       4       473     Diaminopimelate_Epimerase;_Chain_A,_domain_1 & 2-enoyl-CoA_Hydratase;_Chain_A,_domain_1
# 1.20.1580;3.20.20;3.40.50       4       426     ABC_transporter_ATPase_like_fold & TIM_Barrel & Rossmann_fold
# 1.10.3210;3.90.226      4       342     Hypothetical_protein_af1432 & 2-enoyl-CoA_Hydratase;_Chain_A,_domain_1
# 3.20.20;3.40.1550       4       341     TIM_Barrel & Chemotaxis_protein_chec
# 2.160.10;3.65.10        4       262     UDP_N-Acetylglucosamine_Acyltransferase;_domain_1 & UDP-n-acetylglucosamine1-carboxyvinyl-transferase;_Chain

 # # nAssem>=2
# file3="../data/find-novel_ESMonlyGH-AFincN/result-novel-copairs_ID_nAssemblies_nMem_nAllMem_repPlddt_avgPlddt_sortedCombi_rmnAssem1.tsv"
# outfile3="../data/find-novel_ESMonlyGH-AFincN/result-novel-copairs_ID_combi_copairs-CombiRank.tsv"

# gawk -F'\t' -v OFS='\t' '{
#     key = $7
#     count[key]++
#     if (!(key in seen)) {
#         keys[++num_keys] = key
#         seen[key] = 1
#     }
# }

# END {
#     n = asort(keys)
#     for (i = 1; i <= n; i++) {
#         key = keys[i]
#         print key, count[key]
#     }
# }' "$file3" | sort -k2,2nr > "$outfile3"


# uploead cath-names_modified.txt from CATHDB to this dir. 