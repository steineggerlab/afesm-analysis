# Map every taxId of the AFESM taxonomy (NCBI + GTDB) to the rank group used in the figures:
# root, cellular organism, superkingdom, lower than superkingdom, family and lower than family, species and lower than species
# and to its superkingdom
# Outputs (old taxIds in merged.dmp are also written with their current taxon)
#   OUT_FILE: taxId, taxName, taxRank, groupName
#   OUT_FILE_SUPERKINGDOM: taxId, taxName, superkingdomId, superkingdomName

MERGED_DMP = "/share/afesm5/taxonomy/taxdump/merged.dmp"
NAMES_DMP = "/fast/esmfold/databases/afesm_names.dmp"
NODES_DMP = "/fast/esmfold/databases/afesm_nodes.dmp"
OUT_FILE = "/share/afesm6/coreness/grouping_w_merged_dmp_gtdb-taxId_taxName_taxRank_groupName.tsv"
OUT_FILE_SUPERKINGDOM = "/share/afesm6/coreness/grouping_w_merged_dmp_gtdb-taxId_taxName_superkingdomId_superkingdomName.tsv"

# merged.dmp: current taxId -> previous taxIds
cur_id2prev_id = {}
with open(MERGED_DMP) as merged_f:
    for line in merged_f:
        tokens = line.strip().split("\t|\t")
        cur_id = int(tokens[1].strip('\t|'))
        prev_id = int(tokens[0])

        if cur_id in cur_id2prev_id:
            cur_id2prev_id[cur_id].append(prev_id)
        else:
            cur_id2prev_id[cur_id] = [prev_id]

# names.dmp: scientific names
taxName = {}
with open(NAMES_DMP) as f:
    for line in f:
        tokens = line.split("\t|\t")
        if tokens[3] != "scientific name\t|\n":
            continue

        taxName[int(tokens[0])] = tokens[1]

# nodes.dmp: parent and rank
kid_parent = {}
taxRank = {}
with open(NODES_DMP) as f:
    for line in f:
        tokens = line.split("\t|\t")

        kid_parent[int(tokens[0])] = int(tokens[1])
        taxRank[int(tokens[0])] = tokens[2]

dp = {}
dp_groupCode = {}

def dfs(cur):
    if cur == 131567:
        dp[cur] = cur
        dp_groupCode[cur] = 'cellular organism'
        return dp[cur]
    if not cur in kid_parent or cur == kid_parent[cur]:
        if cur == 1:
            dp[cur] = cur
            dp_groupCode[cur] = 'root'
        else:
            dp[cur] = False
            dp_groupCode[cur] = False
        return dp[cur]

    if taxRank[cur] == 'superkingdom':
        dp[cur] = cur
        dp_groupCode[cur] = 'superkingdom'
        return cur
    elif taxRank[cur] == 'family':
        dp[cur] = cur
        dp_groupCode[cur] = 'family and lower than family'
        return cur
    elif taxRank[cur] == 'species':
        dp[cur] = cur
        dp_groupCode[cur] = 'species and lower than species'
        return cur

    next = kid_parent[cur]

    if taxRank[next] == 'superkingdom':
        dp[cur] = cur
        dp_groupCode[cur] = 'lower than superkingdom'
        return cur

    dp[cur] = dfs(next)
    dp_groupCode[cur] = dp_groupCode[next]
    return dp[cur]

for key in kid_parent.keys():
    dfs(key)

with open(OUT_FILE, "w") as f:
    for key, val in dp.items():
        if val:
            f.write(f"{key}\t{taxName[key]}\t{taxRank[key]}\t{dp_groupCode[key]}\n")
            if key in cur_id2prev_id:
                for prev_id in cur_id2prev_id[key]:
                    f.write(f"{prev_id}\t{taxName[key]}\t{taxRank[key]}\t{dp_groupCode[key]}\n")

# superkingdom of every taxId
dp_superkingdom = {}

def dfs_superkingdom(cur):
    if not cur in kid_parent or cur == kid_parent[cur]:
        dp_superkingdom[cur] = False
        return dp_superkingdom[cur]
    if cur in dp_superkingdom:
        return dp_superkingdom[cur]

    if taxRank[cur] == 'superkingdom':
        dp_superkingdom[cur] = cur
        return cur

    next = kid_parent[cur]

    dp_superkingdom[cur] = dfs_superkingdom(next)
    return dp_superkingdom[cur]

for key in kid_parent.keys():
    dfs_superkingdom(key)

with open(OUT_FILE_SUPERKINGDOM, "w") as f:
    for key, val in dp_superkingdom.items():
        if val:
            f.write(f"{key}\t{taxName[key]}\t{val}\t{taxName[val]}\n")
            if key in cur_id2prev_id:
                for prev_id in cur_id2prev_id[key]:
                    f.write(f"{prev_id}\t{taxName[key]}\t{val}\t{taxName[val]}\n")
