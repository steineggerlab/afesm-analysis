#!/usr/bin/env python3
import sys
import os


def parse_ranges(range_str):
    """'51-139_244-287' -> [(51,139),(244,287)]"""
    ranges = []
    for part in range_str.split('_'):
        start, end = part.split('-')
        ranges.append((int(start), int(end)))
    return ranges


def chop_pdb(in_pdb, out_pdb, lo, hi):
    with open(in_pdb) as fin, open(out_pdb, 'w') as fout:
        for line in fin:
            if line.startswith(('ATOM', 'HETATM')):
                resseq = int(line[22:26])
                if lo <= resseq <= hi:
                    fout.write(line)
            elif line.startswith('TER'):
                fout.write(line)
        fout.write('END\n')


def main():
    if len(sys.argv) != 4:
        print(f"Usage: {sys.argv[0]} <pdb_dir> <domain_tsv> <output_dir>")
        sys.exit(1)

    pdb_dir, tsv_file, out_dir = sys.argv[1], sys.argv[2], sys.argv[3]
    os.makedirs(out_dir, exist_ok=True)

    with open(tsv_file) as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            name, range_str = line.split()
            entry_id = name.split('_')[0]

            in_pdb = os.path.join(pdb_dir, f"{entry_id}.pdb")
            if not os.path.exists(in_pdb):
                print(f"[skip] no pdb: {in_pdb}")
                continue

            ranges = parse_ranges(range_str)
            lo = min(s for s, e in ranges)
            hi = max(e for s, e in ranges)

            out_pdb = os.path.join(out_dir, f"{name}.pdb")
            chop_pdb(in_pdb, out_pdb, lo, hi)
            print(f"[done] {name}: {lo}-{hi} -> {out_pdb}")


if __name__ == '__main__':
    main()
