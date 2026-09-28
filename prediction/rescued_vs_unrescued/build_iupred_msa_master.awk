BEGIN {
    FS = OFS = "\t"

    if (qc_summary == "") {
        qc_summary = "iupred_msa_master_qc_summary.tsv"
    }
    if (qc_missing == "") {
        qc_missing = "iupred_msa_master_qc_missing.tsv"
    }
    if (qc_duplicates == "") {
        qc_duplicates = "iupred_msa_master_qc_duplicates.tsv"
    }

    print "metric", "value" > qc_summary
    print "domain_id", "group", "range", "msa_match_status" > qc_missing
    print "domain_id", "group", "range", "msa_join_key", "duplicate_rows", "msa_depth", "match_mode" > qc_duplicates
}

function die(msg) {
    print "ERROR: " msg > "/dev/stderr"
    exit 1
}

function normalize_boundary(boundary, tmp) {
    tmp = boundary
    gsub(/-/, "_", tmp)
    return tmp
}

FNR == 1 {
    file_idx++
}

file_idx == 1 {
    if (NF < 2) {
        die("Malformed row in domain range table at line " FNR)
    }

    domain_id = $1
    boundary = $2

    if ((domain_id in range_by_domain) && range_by_domain[domain_id] != boundary) {
        die("Conflicting boundaries for " domain_id " in domain range table")
    }

    range_by_domain[domain_id] = boundary
    range_rows++
    next
}

file_idx == 2 {
    if (FNR == 1) {
        if ($1 != "domain_id" || $2 != "group" || $3 != "range") {
            die("Unexpected iupred_results.tsv header")
        }
        output_header = $0 OFS "msa_depth" OFS "msa_match_status"
        next
    }

    if (NF < 6) {
        die("Malformed row in iupred results at line " FNR)
    }

    domain_id = $1
    group = $2
    boundary = $3
    num_residues = $4
    mean_iupred = $5
    pct_disordered = $6

    if (!(domain_id in range_by_domain)) {
        die("IUPred domain missing from domain range table: " domain_id)
    }
    if (range_by_domain[domain_id] != boundary) {
        die("Boundary mismatch for " domain_id ": range table=" range_by_domain[domain_id] ", iupred=" boundary)
    }
    if (num_residues !~ /^[0-9]+$/) {
        die("Invalid num_residues for " domain_id ": " num_residues)
    }
    if (mean_iupred !~ /^-?[0-9]+(\.[0-9]+)?$/) {
        die("Invalid mean_iupred for " domain_id ": " mean_iupred)
    }
    if (pct_disordered !~ /^-?[0-9]+(\.[0-9]+)?$/) {
        die("Invalid pct_disordered for " domain_id ": " pct_disordered)
    }

    join_key = domain_id "_" normalize_boundary(boundary)
    if (join_key in row_by_key) {
        die("Duplicate normalized join key in iupred results: " join_key)
    }

    row_by_key[join_key] = $0
    domain_by_key[join_key] = domain_id
    group_by_key[join_key] = group
    boundary_by_key[join_key] = boundary
    discontinuous_by_key[join_key] = (boundary ~ /_/)
    ordered_keys[++n_keys] = join_key
    iupred_rows++
    next
}

file_idx == 3 {
    if (FNR == 1) {
        if ($1 != "domain_id" || $2 != "msa_depth") {
            die("Unexpected domain_to_msa_depth.tsv header")
        }
        next
    }

    if (NF < 2) {
        die("Malformed row in MSA depth table at line " FNR)
    }

    join_key = $1
    msa_depth = $2
    n = split(join_key, parts, "_")
    domain_only = parts[1] "_" parts[2]

    if (join_key !~ /^MGYP[0-9]+_[0-9]+_[0-9]+_[0-9]+$/) {
        die("Unexpected MSA join key format at line " FNR ": " join_key)
    }
    if (msa_depth !~ /^[0-9]+$/) {
        die("Invalid msa_depth at line " FNR ": " msa_depth)
    }

    msa_rows++
    domain_row_count[domain_only]++

    if (!(domain_only in first_join_key_by_domain)) {
        first_join_key_by_domain[domain_only] = join_key
        first_depth_by_domain[domain_only] = msa_depth
    }

    if (!(join_key in row_by_key)) {
        next
    }

    if (!(join_key in msa_by_key)) {
        msa_by_key[join_key] = msa_depth
        duplicate_rows_by_key[join_key] = 1
    } else if (msa_by_key[join_key] != msa_depth) {
        die("Conflicting MSA depth values for " join_key ": " msa_by_key[join_key] " vs " msa_depth)
    } else {
        duplicate_rows_by_key[join_key]++
    }

    next
}

END {
    if (file_idx != 3) {
        die("Expected exactly 3 input files")
    }

    print output_header

    matched = 0
    exact_matched = 0
    domain_fallback_matched = 0
    missing_total = 0
    missing_discontinuous = 0
    missing_other = 0
    duplicate_match_keys = 0

    for (i = 1; i <= n_keys; i++) {
        join_key = ordered_keys[i]
        domain_id = domain_by_key[join_key]
        group = group_by_key[join_key]
        boundary = boundary_by_key[join_key]

        if (join_key in msa_by_key) {
            status = "matched"
            depth_out = msa_by_key[join_key]
            match_mode = "exact_boundary"
            matched++
            exact_matched++

            if (duplicate_rows_by_key[join_key] > 1) {
                duplicate_match_keys++
                print domain_id, group, boundary, join_key, duplicate_rows_by_key[join_key], depth_out, match_mode >> qc_duplicates
            }
        } else if (domain_row_count[domain_id] == 1) {
            status = "matched"
            depth_out = first_depth_by_domain[domain_id]
            match_mode = "domain_id_fallback"
            matched++
            domain_fallback_matched++
        } else if (discontinuous_by_key[join_key]) {
            status = "unmapped_discontinuous"
            depth_out = "NA"
            match_mode = "unmatched"
            missing_total++
            missing_discontinuous++
            print domain_id, group, boundary, status >> qc_missing
        } else {
            status = "unmapped_missing"
            depth_out = "NA"
            match_mode = "unmatched"
            missing_total++
            missing_other++
            print domain_id, group, boundary, status >> qc_missing
        }

        print row_by_key[join_key], depth_out, status
    }

    print "domain_range_rows", range_rows >> qc_summary
    print "iupred_rows", iupred_rows >> qc_summary
    print "msa_rows", msa_rows >> qc_summary
    print "matched_rows", matched >> qc_summary
    print "matched_rows_exact_boundary", exact_matched >> qc_summary
    print "matched_rows_domain_id_fallback", domain_fallback_matched >> qc_summary
    print "missing_rows_total", missing_total >> qc_summary
    print "missing_rows_discontinuous", missing_discontinuous >> qc_summary
    print "missing_rows_other", missing_other >> qc_summary
    print "duplicate_match_keys_collapsed", duplicate_match_keys >> qc_summary
}
