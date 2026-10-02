#!/usr/bin/env python3
"""
Compute average pLDDT of the AF2-ColabFold models of the abandoned domains from foldcomp database.

Input  : allreps_lowqual_domains_shuf.tsv
         col1: entryId
         col2: start,end,domainId[,start,end,domainId,...]  (1-based inclusive, can repeat for discontinuous domains)

Output : /share/afesm6/50_novel_struct_dl/novel_domain-domainId_plddt.tsv
         col1: domainId
         col2: avgPlddt

Architecture (producer-consumer):
  main thread   : reads foldcomp sequentially → task_q (bounded)
  N_THREADS     : task_q → compute pLDDT → result_q
  main thread   : result_q → write TSV + tqdm
"""

import os
import sys
import threading
from collections import defaultdict
from pathlib import Path
from queue import Empty, Queue

import foldcomp
import numpy as np
from tqdm import tqdm

N_THREADS   = os.cpu_count()
QUEUE_DEPTH = N_THREADS * 4   # backpressure: caps pdb_str strings in flight

INPUT_TSV   = "/share/afesm6/23_abandoned_domains/allreps_lowqual_domains_shuf.tsv"
FOLDCOMP_DB = "/fast/esmfold/abandoned_preds/database/pdb_final_comp"   # AF2-ColabFold models of the abandoned domains
OUTPUT_TSV  = "/share/afesm6/50_novel_struct_dl/novel_domain-domainId_plddt.tsv"


def parse_domains(filepath):
    """Returns {domainId: [(start, end), ...]} (1-based, inclusive, original protein coords)."""
    domains = defaultdict(list)
    with open(filepath) as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            cols = line.split("\t")
            if len(cols) < 2:
                continue
            fields = cols[1].split(",")
            i = 0
            while i + 2 < len(fields):
                domains[fields[i + 2]].append((int(fields[i]), int(fields[i + 1])))
                i += 3
    return dict(domains)


def build_name_lookup(lookup_path):
    """
    Map domain_prefix (e.g. MGYP001553081548_03) -> full foldcomp entry name.
    Entry name format: {MGYP_id}_{domNum}_{start}_{end}_unrelaxed_...
    MGYP IDs contain no underscores, so splitting on '_' is safe.
    """
    lookup = {}
    with open(lookup_path) as f:
        for line in f:
            parts = line.rstrip("\n").split("\t")
            if len(parts) < 2:
                continue
            name = parts[1]
            tokens = name.split("_")
            if len(tokens) >= 2:
                lookup[f"{tokens[0]}_{tokens[1]}"] = name
    return lookup


def avg_plddt(pdb_str, allowed_pdb_resnums=None):
    """Return mean pLDDT (B-factor of CA) from PDB string via direct line parsing."""
    values = []
    for line in pdb_str.splitlines():
        if not line.startswith("ATOM"):
            continue
        if line[12:16].strip() != "CA":
            continue
        resnum = int(line[22:26])
        if allowed_pdb_resnums is not None and resnum not in allowed_pdb_resnums:
            continue
        values.append(float(line[60:66]))
    return float(np.mean(values)) if values else None


def _worker(task_q, result_q):
    """Consume (domain_id, segments, pdb_str) tasks, emit (domain_id, value_or_exc)."""
    while True:
        item = task_q.get()
        task_q.task_done()
        if item is None:           # poison pill
            return
        domain_id, segments, pdb_str = item
        try:
            min_start = min(s for s, e in segments)
            allowed = {r - min_start + 1 for s, e in segments for r in range(s, e + 1)}
            val = avg_plddt(pdb_str, allowed_pdb_resnums=allowed)
        except Exception as exc:
            val = exc
        result_q.put((domain_id, val))


def main():
    print("Parsing domain TSV...", file=sys.stderr)
    domains = parse_domains(INPUT_TSV)
    print(f"  {len(domains):,} unique domains", file=sys.stderr)

    print("Building foldcomp name lookup...", file=sys.stderr)
    name_lookup = build_name_lookup(f"{FOLDCOMP_DB}.lookup")
    print(f"  {len(name_lookup):,} entries in foldcomp", file=sys.stderr)

    fetch_map = {}
    n_missing = 0
    for domain_id, segments in domains.items():
        full_name = name_lookup.get(domain_id)
        if full_name is None:
            print(f"  MISSING: {domain_id}", file=sys.stderr)
            n_missing += 1
        else:
            fetch_map[full_name] = (domain_id, segments)

    print(f"  {len(fetch_map):,} found, {n_missing:,} not in foldcomp", file=sys.stderr)

    Path(OUTPUT_TSV).parent.mkdir(parents=True, exist_ok=True)

    task_q   = Queue(maxsize=QUEUE_DEPTH)
    result_q = Queue()

    workers = [
        threading.Thread(target=_worker, args=(task_q, result_q), daemon=True)
        for _ in range(N_THREADS)
    ]
    for w in workers:
        w.start()

    n_ok = n_err = n_submitted = 0
    total = len(fetch_map)

    with foldcomp.open(FOLDCOMP_DB, ids=list(fetch_map.keys())) as db, \
         open(OUTPUT_TSV, "w") as out, \
         tqdm(total=total, desc="pLDDT") as pbar:

        def _handle(domain_id, val):
            nonlocal n_ok, n_err
            if isinstance(val, Exception):
                tqdm.write(f"  ERROR {domain_id}: {val}")
                n_err += 1
            elif val is None:
                tqdm.write(f"  WARN: no CA for {domain_id}")
                n_err += 1
            else:
                out.write(f"{domain_id}\t{val:.4f}\n")
                n_ok += 1
            pbar.update(1)

        # Producer: main thread reads foldcomp and feeds task_q.
        # task_q is bounded → blocks here when workers are busy (backpressure).
        for full_name, pdb_str in db:
            domain_id, segments = fetch_map[full_name]
            task_q.put((domain_id, segments, pdb_str))
            n_submitted += 1

            # drain any results that are already ready (non-blocking)
            try:
                while True:
                    _handle(*result_q.get_nowait())
            except Empty:
                pass

        # send poison pills to stop workers
        for _ in range(N_THREADS):
            task_q.put(None)

        # drain remaining results
        while n_ok + n_err < n_submitted:
            _handle(*result_q.get())

    for w in workers:
        w.join()

    print(
        f"Done: {n_ok:,} written, {n_err:,} errors, {n_missing:,} not found",
        file=sys.stderr,
    )


if __name__ == "__main__":
    main()
