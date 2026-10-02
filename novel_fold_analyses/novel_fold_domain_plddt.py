#!/usr/bin/env python3
# average pLDDT of the novel fold domains (Supp. Fig. 12c)
"""
usage: novel_fold_domain_plddt.py <novel_domain_list> <struct_dir> <output.tsv>

residue 번호가 1부터 시작하면 -> 도메인만 이어붙인 구조로 보고 전체 사용 (concat)
그렇지 않으면 -> 원본 numbering 유지로 보고 도메인 구간 residue만 사용 (orig)

output: domainId  rank  file  n_res  mode  avg_plddt
"""
import os
import re
import sys
import glob
import gzip


def parse_regions(s):
    segs = []
    for part in s.split("_"):
        if "-" not in part:
            continue
        a, b = part.split("-")
        segs.append((int(a), int(b)))
    return sorted(segs)


def open_maybe_gz(path):
    return gzip.open(path, "rt") if path.endswith(".gz") else open(path, "r")


def read_pdb_plddt(path):
    vals = {}
    with open_maybe_gz(path) as f:
        for line in f:
            if not line.startswith(("ATOM  ", "HETATM")):
                continue
            atom = line[12:16].strip()
            try:
                resnum = int(line[22:26])
                b = float(line[60:66])
            except ValueError:
                continue
            if atom == "CA" or resnum not in vals:
                vals[resnum] = b
    return vals


def read_cif_plddt(path):
    vals = {}
    with open_maybe_gz(path) as f:
        cols, in_loop, idx = {}, False, 0
        for line in f:
            line = line.rstrip("\n")
            if line.startswith("loop_"):
                cols, in_loop, idx = {}, False, 0
                continue
            if line.startswith("_atom_site."):
                cols[line.strip().split(".", 1)[1]] = idx
                idx += 1
                in_loop = True
                continue
            if in_loop:
                if not line.strip() or line.startswith(("#", "_")):
                    if cols:
                        in_loop = False
                    continue
                p = line.split()
                if len(p) < idx:
                    continue
                try:
                    ci = cols.get("auth_seq_id", cols.get("label_seq_id"))
                    resnum = int(p[ci])
                    b = float(p[cols["B_iso_or_equiv"]])
                except (ValueError, KeyError, TypeError):
                    continue
                atom = p[cols["label_atom_id"]] if "label_atom_id" in cols else ""
                if atom == "CA" or resnum not in vals:
                    vals[resnum] = b
    return vals


def read_plddt(path):
    low = path.lower()
    return read_cif_plddt(path) if low.endswith((".cif", ".cif.gz")) else read_pdb_plddt(path)


RANK_RE = re.compile(r"_rank_?(\d+)")


def split_key(basename):
    stem = basename
    for ext in (".gz", ".pdb", ".cif"):
        if stem.endswith(ext):
            stem = stem[: -len(ext)]
    m = RANK_RE.search(stem)
    return (stem[: m.start()], m.group(1)) if m else (stem, "")


def select_residues(vals, segs):
    resnums = sorted(vals)
    if resnums[0] == 1:
        # 1부터 시작 -> 도메인만 있는 구조, 전부 사용
        return [vals[r] for r in resnums], "concat"
    # 원본 numbering -> 도메인 구간만 사용
    keep = set()
    for s, e in segs:
        keep.update(range(s, e + 1))
    return [vals[r] for r in resnums if r in keep], "orig"


def main():
    if len(sys.argv) != 4:
        sys.exit(__doc__)
    list_file, struct_dir, out_file = sys.argv[1:4]

    domains = {}
    with open(list_file) as f:
        for line in f:
            p = line.rstrip("\n").split()
            if len(p) >= 2 and p[0]:
                domains[p[0]] = parse_regions(p[1])

    files = []
    for ext in ("*.pdb", "*.pdb.gz", "*.cif", "*.cif.gz"):
        files.extend(glob.glob(os.path.join(struct_dir, "**", ext), recursive=True))

    rows = []
    seen = set()
    for path in sorted(files):
        base = os.path.basename(path)
        domain_id, rank = split_key(base)
        segs = domains.get(domain_id) or domains.get(domain_id.split("_")[0])
        if not segs:
            print(f"[skip] no region entry: {base}", file=sys.stderr)
            continue

        vals = read_plddt(path)
        if not vals:
            print(f"[skip] no atoms parsed: {base}", file=sys.stderr)
            continue

        used, mode = select_residues(vals, segs)
        if not used:
            print(f"[skip] empty selection: {base}", file=sys.stderr)
            continue

        avg = sum(used) / len(used)
        if avg <= 1.0:
            avg *= 100.0
        rows.append((domain_id, rank, base, len(used), mode, avg))
        seen.add(domain_id)

    for m in sorted(set(domains) - seen):
        print(f"[missing] no structure file: {m}", file=sys.stderr)

    rows.sort(key=lambda x: (x[0], x[1]))
    with open(out_file, "w") as out:
        out.write("domainId\trank\tfile\tn_res\tmode\tavg_plddt\n")
        for d, r, b, n, mode, avg in rows:
            out.write(f"{d}\t{r}\t{b}\t{n}\t{mode}\t{avg:.3f}\n")

    print(f"saved -> {out_file}  ({len(rows)} structures, {len(seen)}/{len(domains)} domains)")


if __name__ == "__main__":
    main()
