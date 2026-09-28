#!/usr/bin/env python3
"""Alternate H-level Novel-vs-Non-novel MDP analysis (5203 vs 134576)."""

from __future__ import annotations

import csv
import gzip
import math
import os
import statistics
from collections import defaultdict
from typing import Dict, Iterable, List, Sequence, Tuple


ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUTDIR = os.path.join(ROOT, "mdp_novel_vs_non_hlevel5203")

LEGACY_NOVEL_PATH = os.path.join(
    ROOT,
    "data",
    "trashcan",
    "1_extract-H_concat-RESULT-sorted-multi-ID_Hcombi_Hpair_Tpairs-sortedTpairs-NOVEL.tsv",
)
BROAD_NOVEL_PATH = os.path.join(
    ROOT, "data", "incN_result-novel-copairs_ID_combi_copairs.tsv"
)
BOUNDARY_PATH = os.path.join(
    ROOT, "data", "annotated_table_newclusters_provisional_nonewfoldsinfo.tsv"
)


def parse_boundary_length(boundary: str) -> int:
    total = 0
    for part in boundary.split("_"):
        start_s, end_s = part.split("-")
        start = int(start_s)
        end = int(end_s)
        if end < start:
            raise ValueError(f"invalid boundary with end < start: {boundary}")
        total += end - start + 1
    return total


def t_level(cath_label: str) -> str:
    parts = cath_label.split(".")
    if len(parts) < 3:
        raise ValueError(f"unexpected CATH label: {cath_label}")
    return ".".join(parts[:3])


def load_unique_ids(path: str) -> List[str]:
    seen = set()
    ordered: List[str] = []
    with open(path, "r", encoding="utf-8") as handle:
        for line in handle:
            if not line.strip():
                continue
            protein_id = line.rstrip("\n").split("\t", 1)[0]
            if protein_id not in seen:
                seen.add(protein_id)
                ordered.append(protein_id)
    return ordered


def quantile(sorted_vals: Sequence[float], q: float) -> float:
    if not sorted_vals:
        return float("nan")
    if len(sorted_vals) == 1:
        return float(sorted_vals[0])
    pos = (len(sorted_vals) - 1) * q
    lo = int(math.floor(pos))
    hi = int(math.ceil(pos))
    if lo == hi:
        return float(sorted_vals[lo])
    frac = pos - lo
    return float(sorted_vals[lo] + (sorted_vals[hi] - sorted_vals[lo]) * frac)


def summarize(values: Sequence[float]) -> Dict[str, float]:
    vals = list(values)
    vals_sorted = sorted(vals)
    n = len(vals_sorted)
    mean = statistics.fmean(vals_sorted) if vals_sorted else float("nan")
    median = statistics.median(vals_sorted) if vals_sorted else float("nan")
    sd = statistics.stdev(vals_sorted) if n > 1 else 0.0
    return {
        "n": float(n),
        "mean": mean,
        "median": median,
        "sd": sd,
        "min": float(vals_sorted[0]) if vals_sorted else float("nan"),
        "q1": quantile(vals_sorted, 0.25),
        "q3": quantile(vals_sorted, 0.75),
        "max": float(vals_sorted[-1]) if vals_sorted else float("nan"),
    }


def mann_whitney_u(x: Sequence[float], y: Sequence[float]) -> Dict[str, float]:
    x_vals = list(x)
    y_vals = list(y)
    n1 = len(x_vals)
    n2 = len(y_vals)
    pooled: List[Tuple[float, int]] = [(float(v), 0) for v in x_vals] + [
        (float(v), 1) for v in y_vals
    ]
    pooled.sort(key=lambda item: item[0])

    rank_sum_x = 0.0
    tie_sum = 0
    i = 0
    n = n1 + n2
    while i < n:
        j = i + 1
        while j < n and pooled[j][0] == pooled[i][0]:
            j += 1
        avg_rank = (i + 1 + j) / 2.0
        tie_size = j - i
        if tie_size > 1:
            tie_sum += tie_size**3 - tie_size
        for k in range(i, j):
            if pooled[k][1] == 0:
                rank_sum_x += avg_rank
        i = j

    u1 = rank_sum_x - n1 * (n1 + 1) / 2.0
    u2 = n1 * n2 - u1
    mean_u = n1 * n2 / 2.0
    if n > 1:
        var_u = n1 * n2 / 12.0 * ((n + 1) - tie_sum / (n * (n - 1)))
    else:
        var_u = 0.0
    if var_u > 0:
        cc = 0.5 if u1 > mean_u else (-0.5 if u1 < mean_u else 0.0)
        z = (u1 - mean_u - cc) / math.sqrt(var_u)
        p = math.erfc(abs(z) / math.sqrt(2.0))
    else:
        z = 0.0
        p = 1.0
    delta = (2.0 * u1) / (n1 * n2) - 1.0 if n1 and n2 else float("nan")
    return {
        "u1": u1,
        "u2": u2,
        "z": z,
        "p_two_sided": p,
        "cliffs_delta": delta,
    }


def write_lines(path: str, values: Iterable[str]) -> None:
    with open(path, "w", encoding="utf-8") as handle:
        for value in values:
            handle.write(f"{value}\n")


def main() -> None:
    os.makedirs(OUTDIR, exist_ok=True)

    legacy_novel_ids = load_unique_ids(LEGACY_NOVEL_PATH)
    broad_novel_ids = load_unique_ids(BROAD_NOVEL_PATH)
    legacy_novel_set = set(legacy_novel_ids)
    broad_novel_set = set(broad_novel_ids)

    all_proteins = set()
    hlevel_labels: Dict[str, set] = defaultdict(set)
    per_protein_all: Dict[str, Dict[str, object]] = {}

    with open(BOUNDARY_PATH, "r", encoding="utf-8") as in_handle:
        reader = csv.DictReader(in_handle, delimiter="\t")
        for row in reader:
            protein_id = row["dom_ID"].rsplit("_", 1)[0]
            all_proteins.add(protein_id)
            if protein_id not in per_protein_all:
                per_protein_all[protein_id] = {
                    "total_domains": 0,
                    "cath_domains": 0,
                    "non_cath_domains": 0,
                    "cath_lengths": [],
                    "all_lengths": [],
                    "t_levels": set(),
                }
            if (
                row["globularity"] == "G"
                and row["cath_assignment_level"] == "H"
                and row["cath_label"] != "-"
            ):
                hlevel_labels[protein_id].add(row["cath_label"])

    broad_non_novel_set = all_proteins - broad_novel_set
    hlevel_qualified = {
        protein_id for protein_id, labels in hlevel_labels.items() if len(labels) >= 2
    }
    non_novel_ids = sorted(broad_non_novel_set & hlevel_qualified)
    non_novel_set = set(non_novel_ids)

    if not legacy_novel_set.issubset(broad_novel_set):
        missing = sorted(legacy_novel_set - broad_novel_set)[:10]
        raise SystemExit(f"Legacy Novel IDs missing from broad Novel set: {missing}")
    if not legacy_novel_set.issubset(hlevel_qualified):
        missing = sorted(legacy_novel_set - hlevel_qualified)[:10]
        raise SystemExit(f"Legacy Novel IDs missing from H-level-qualified set: {missing}")

    analysis_ids = legacy_novel_ids + non_novel_ids
    analysis_set = set(analysis_ids)

    write_lines(os.path.join(OUTDIR, "legacy_novel_ids_5203.txt"), legacy_novel_ids)
    write_lines(os.path.join(OUTDIR, "broad_novel_ids_11941.txt"), broad_novel_ids)
    write_lines(
        os.path.join(OUTDIR, "non_novel_hlevel_ids_134576.txt"), non_novel_ids
    )

    per_protein: Dict[str, Dict[str, object]] = {}
    for protein_id in analysis_ids:
        per_protein[protein_id] = {
            "set_label": "novel" if protein_id in legacy_novel_set else "non_novel",
            "total_domains": 0,
            "cath_domains": 0,
            "non_cath_domains": 0,
            "cath_lengths": [],
            "all_lengths": [],
            "t_levels": set(),
        }

    per_domain_path = os.path.join(OUTDIR, "mdp_domain_rows.tsv.gz")
    cath_domain_lengths_by_set: Dict[str, List[int]] = {"novel": [], "non_novel": []}
    calc_len_mismatch = 0
    cath_flag_disagree = 0

    with gzip.open(per_domain_path, "wt", encoding="utf-8", newline="") as out_handle:
        writer = csv.writer(out_handle, delimiter="\t")
        writer.writerow(
            [
                "set_label",
                "protein_id",
                "dom_id",
                "boundary",
                "length_reported",
                "length_calculated",
                "cath_label",
                "cath_assignment_level",
                "globularity",
                "classification",
                "is_cath_annotated",
                "t_level",
            ]
        )

        with open(BOUNDARY_PATH, "r", encoding="utf-8") as in_handle:
            reader = csv.DictReader(in_handle, delimiter="\t")
            for row in reader:
                dom_id = row["dom_ID"]
                protein_id = dom_id.rsplit("_", 1)[0]
                if protein_id not in analysis_set:
                    continue

                length_calc = parse_boundary_length(row["boundary"])
                length_reported = int(row["length"])
                if length_calc != length_reported:
                    calc_len_mismatch += 1

                cath_label = row["cath_label"]
                level = row["cath_assignment_level"]
                is_cath = cath_label != "-"
                level_implies_cath = level in {"H", "T"}
                if is_cath != level_implies_cath:
                    cath_flag_disagree += 1

                rec = per_protein[protein_id]
                rec["total_domains"] = int(rec["total_domains"]) + 1
                cast_all_lengths = rec["all_lengths"]
                assert isinstance(cast_all_lengths, list)
                cast_all_lengths.append(length_calc)

                tlvl = "-"
                if is_cath:
                    rec["cath_domains"] = int(rec["cath_domains"]) + 1
                    cast_cath_lengths = rec["cath_lengths"]
                    assert isinstance(cast_cath_lengths, list)
                    cast_cath_lengths.append(length_calc)
                    tlvl = t_level(cath_label)
                    cast_t_levels = rec["t_levels"]
                    assert isinstance(cast_t_levels, set)
                    cast_t_levels.add(tlvl)
                    cath_domain_lengths_by_set[str(rec["set_label"])].append(length_calc)
                else:
                    rec["non_cath_domains"] = int(rec["non_cath_domains"]) + 1

                writer.writerow(
                    [
                        rec["set_label"],
                        protein_id,
                        dom_id,
                        row["boundary"],
                        length_reported,
                        length_calc,
                        cath_label,
                        level,
                        row["globularity"],
                        row["classification"],
                        1 if is_cath else 0,
                        tlvl,
                    ]
                )

    missing_boundary = sorted(
        pid for pid, rec in per_protein.items() if rec["total_domains"] == 0
    )
    if missing_boundary:
        raise SystemExit(f"Proteins missing boundary rows: first few {missing_boundary[:10]}")

    for protein_id, rec in per_protein.items():
        rec["t_level_count"] = len(rec["t_levels"])  # type: ignore[arg-type]
        rec["cath_ratio"] = float(rec["cath_domains"]) / float(rec["total_domains"])  # type: ignore[arg-type]
        cath_lengths = rec["cath_lengths"]  # type: ignore[assignment]
        all_lengths = rec["all_lengths"]  # type: ignore[assignment]
        rec["mean_cath_length"] = statistics.fmean(cath_lengths) if cath_lengths else float("nan")
        rec["median_cath_length"] = statistics.median(cath_lengths) if cath_lengths else float("nan")
        rec["mean_all_domain_length"] = statistics.fmean(all_lengths) if all_lengths else float("nan")
        rec["median_all_domain_length"] = statistics.median(all_lengths) if all_lengths else float("nan")

    per_protein_path = os.path.join(OUTDIR, "mdp_per_protein_summary.tsv")
    with open(per_protein_path, "w", encoding="utf-8", newline="") as handle:
        writer = csv.writer(handle, delimiter="\t")
        writer.writerow(
            [
                "protein_id",
                "set_label",
                "total_domains",
                "cath_domains",
                "non_cath_domains",
                "cath_ratio",
                "t_level_count",
                "mean_cath_length",
                "median_cath_length",
                "mean_all_domain_length",
                "median_all_domain_length",
            ]
        )
        for protein_id in analysis_ids:
            rec = per_protein[protein_id]
            writer.writerow(
                [
                    protein_id,
                    rec["set_label"],
                    rec["total_domains"],
                    rec["cath_domains"],
                    rec["non_cath_domains"],
                    f"{rec['cath_ratio']:.10f}",
                    rec["t_level_count"],
                    f"{rec['mean_cath_length']:.10f}",
                    f"{rec['median_cath_length']:.10f}",
                    f"{rec['mean_all_domain_length']:.10f}",
                    f"{rec['median_all_domain_length']:.10f}",
                ]
            )

    metrics = [
        ("total_domains", "Total domains per protein"),
        ("cath_domains", "CATH-annotated domains per protein"),
        ("cath_ratio", "CATH-annotated ratio per protein"),
        ("mean_all_domain_length", "Mean domain length per protein (all domains)"),
        ("mean_cath_length", "Mean CATH-domain length per protein"),
        ("median_cath_length", "Median CATH-domain length per protein"),
    ]

    stats_rows = []
    for key, label in metrics:
        novel_vals = [float(per_protein[pid][key]) for pid in legacy_novel_ids]
        non_vals = [float(per_protein[pid][key]) for pid in non_novel_ids]
        novel_summary = summarize(novel_vals)
        non_summary = summarize(non_vals)
        infer = mann_whitney_u(novel_vals, non_vals)
        row = {
            "metric_key": key,
            "metric_label": label,
            "novel_n": int(novel_summary["n"]),
            "novel_mean": novel_summary["mean"],
            "novel_median": novel_summary["median"],
            "novel_q1": novel_summary["q1"],
            "novel_q3": novel_summary["q3"],
            "novel_sd": novel_summary["sd"],
            "non_novel_n": int(non_summary["n"]),
            "non_novel_mean": non_summary["mean"],
            "non_novel_median": non_summary["median"],
            "non_novel_q1": non_summary["q1"],
            "non_novel_q3": non_summary["q3"],
            "non_novel_sd": non_summary["sd"],
            "u1": infer["u1"],
            "z": infer["z"],
            "p_two_sided": infer["p_two_sided"],
            "cliffs_delta": infer["cliffs_delta"],
        }
        stats_rows.append(row)

    pooled_rows = []
    for set_label in ("novel", "non_novel"):
        vals = cath_domain_lengths_by_set[set_label]
        summary = summarize(vals)
        pooled_rows.append(
            {
                "set_label": set_label,
                "n": int(summary["n"]),
                "mean": summary["mean"],
                "median": summary["median"],
                "q1": summary["q1"],
                "q3": summary["q3"],
                "sd": summary["sd"],
                "min": summary["min"],
                "max": summary["max"],
            }
        )
    pooled_infer = mann_whitney_u(
        cath_domain_lengths_by_set["novel"], cath_domain_lengths_by_set["non_novel"]
    )

    stats_path = os.path.join(OUTDIR, "stats_summary.tsv")
    with open(stats_path, "w", encoding="utf-8", newline="") as handle:
        writer = csv.writer(handle, delimiter="\t")
        writer.writerow(
            [
                "metric_key",
                "metric_label",
                "novel_n",
                "novel_mean",
                "novel_median",
                "novel_q1",
                "novel_q3",
                "novel_sd",
                "non_novel_n",
                "non_novel_mean",
                "non_novel_median",
                "non_novel_q1",
                "non_novel_q3",
                "non_novel_sd",
                "u1",
                "z",
                "p_two_sided",
                "cliffs_delta",
            ]
        )
        for row in stats_rows:
            writer.writerow(
                [
                    row["metric_key"],
                    row["metric_label"],
                    row["novel_n"],
                    f"{row['novel_mean']:.10f}",
                    f"{row['novel_median']:.10f}",
                    f"{row['novel_q1']:.10f}",
                    f"{row['novel_q3']:.10f}",
                    f"{row['novel_sd']:.10f}",
                    row["non_novel_n"],
                    f"{row['non_novel_mean']:.10f}",
                    f"{row['non_novel_median']:.10f}",
                    f"{row['non_novel_q1']:.10f}",
                    f"{row['non_novel_q3']:.10f}",
                    f"{row['non_novel_sd']:.10f}",
                    f"{row['u1']:.10f}",
                    f"{row['z']:.10f}",
                    f"{row['p_two_sided']:.10e}",
                    f"{row['cliffs_delta']:.10f}",
                ]
            )

    pooled_path = os.path.join(OUTDIR, "pooled_cath_domain_length_summary.tsv")
    with open(pooled_path, "w", encoding="utf-8", newline="") as handle:
        writer = csv.writer(handle, delimiter="\t")
        writer.writerow(["set_label", "n", "mean", "median", "q1", "q3", "sd", "min", "max"])
        for row in pooled_rows:
            writer.writerow(
                [
                    row["set_label"],
                    row["n"],
                    f"{row['mean']:.10f}",
                    f"{row['median']:.10f}",
                    f"{row['q1']:.10f}",
                    f"{row['q3']:.10f}",
                    f"{row['sd']:.10f}",
                    f"{row['min']:.10f}",
                    f"{row['max']:.10f}",
                ]
            )
        writer.writerow([])
        writer.writerow(["comparison", "u1", "z", "p_two_sided", "cliffs_delta"])
        writer.writerow(
            [
                "novel_vs_non_novel",
                f"{pooled_infer['u1']:.10f}",
                f"{pooled_infer['z']:.10f}",
                f"{pooled_infer['p_two_sided']:.10e}",
                f"{pooled_infer['cliffs_delta']:.10f}",
            ]
        )

    validation_path = os.path.join(OUTDIR, "validation_summary.tsv")
    with open(validation_path, "w", encoding="utf-8", newline="") as handle:
        writer = csv.writer(handle, delimiter="\t")
        writer.writerow(["check", "value"])
        writer.writerow(["All_proteins_in_boundary", len(all_proteins)])
        writer.writerow(["Broad_novel_unique_ids", len(broad_novel_set)])
        writer.writerow(["Legacy_novel_unique_ids", len(legacy_novel_set)])
        writer.writerow(["Legacy_novel_subset_of_broad_novel", int(legacy_novel_set.issubset(broad_novel_set))])
        writer.writerow(["Hlevel_qualified_total", len(hlevel_qualified)])
        writer.writerow(["Broad_novel_overlapping_hlevel_qualified", len(broad_novel_set & hlevel_qualified)])
        writer.writerow(["Legacy_novel_overlapping_hlevel_qualified", len(legacy_novel_set & hlevel_qualified)])
        writer.writerow(["Non_novel_hlevel_ids", len(non_novel_set)])
        writer.writerow(["Boundary_length_mismatches", calc_len_mismatch])
        writer.writerow(["CATH_flag_disagreements", cath_flag_disagree])
        writer.writerow(["Proteins_missing_boundary_rows", len(missing_boundary)])
        writer.writerow(["Novel_total_cath_domains", len(cath_domain_lengths_by_set["novel"])])
        writer.writerow(["Non_novel_total_cath_domains", len(cath_domain_lengths_by_set["non_novel"])])

    results_path = os.path.join(OUTDIR, "results.md")
    with open(results_path, "w", encoding="utf-8") as handle:
        handle.write("# Alternate H-level Novel-vs-Non-novel analysis results\n\n")
        handle.write("Date: `2026-06-25`\n\n")
        handle.write("## Set logic\n\n")
        handle.write("- Legacy Novel set: `5,203` proteins from the old H-level Novel file\n")
        handle.write("- Broad Novel exclusion set: `11,941` proteins from `incN_result-novel-copairs_ID_combi_copairs.tsv`\n")
        handle.write("- Alternate Non-novel set: proteins **not** in the broad Novel set and with `>=2` distinct H-level (`N.N.N.N`) assignments using only rows with `globularity = G` and `cath_assignment_level = H`\n\n")
        handle.write("Observed counts:\n\n")
        handle.write(f"- all proteins in boundary table: `{len(all_proteins):,}`\n")
        handle.write(f"- H-level-qualified proteins: `{len(hlevel_qualified):,}`\n")
        handle.write(f"- broad Novel overlap with H-level-qualified proteins: `{len(broad_novel_set & hlevel_qualified):,}`\n")
        handle.write(f"- Legacy Novel set: `{len(legacy_novel_ids):,}`\n")
        handle.write(f"- alternate Non-novel set: `{len(non_novel_ids):,}`\n\n")
        handle.write("## Main metric means\n\n")
        for row in stats_rows:
            if row["metric_key"] not in {"total_domains", "cath_ratio", "mean_all_domain_length"}:
                continue
            handle.write(
                f"- {row['metric_label']}: Novel `{row['novel_mean']:.4f}` vs Non-novel `{row['non_novel_mean']:.4f}`\n"
            )
        handle.write("\n## Note\n\n")
        handle.write(
            "This alternate version is separate from the current primary `11,941`-based analysis and uses a different Non-novel background by design.\n"
        )

    print("Wrote:")
    for rel in [
        "legacy_novel_ids_5203.txt",
        "broad_novel_ids_11941.txt",
        "non_novel_hlevel_ids_134576.txt",
        "mdp_domain_rows.tsv.gz",
        "mdp_per_protein_summary.tsv",
        "stats_summary.tsv",
        "pooled_cath_domain_length_summary.tsv",
        "validation_summary.tsv",
        "results.md",
    ]:
        print(os.path.join("mdp_novel_vs_non_hlevel5203", rel))


if __name__ == "__main__":
    main()
