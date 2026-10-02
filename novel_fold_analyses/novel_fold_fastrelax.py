#!/usr/bin/env python
"""
FastRelax on the 45 novel fold domain models (Supp. Fig. 11).
Relaxes each structure with Rosetta FastRelax (ref2015), records pre/post
score and CA-RMSD, writes relaxed PDBs + a summary TSV.

Parallel: one relax per worker process (PyRosetta is not thread-safe).

Usage:
    python novel_fold_fastrelax.py [N_WORKERS]   (conda env with PyRosetta)
If N_WORKERS is omitted, uses $SLURM_CPUS_PER_TASK (from `srun -c`) or all cores.

NOTE: outputs are OVERWRITTEN on each run (relaxed PDBs + summary TSV).
"""
import os
import sys
import glob
import csv
import logging
import multiprocessing as mp
from datetime import datetime

IN_DIR  = "/share/afesm6/52_fastrelax/database/pdbs/"   # novel_fold_fastrelax_commands.sh
OUT_DIR = "/share/afesm6/52_fastrelax/output/"
SUMMARY = os.path.join(OUT_DIR, "fastrelax_summary.tsv")
LOGFILE = os.path.join(OUT_DIR, "fastrelax.log")

# PyRosetta init flags. Append " -mute core basic protocols" for quieter internals.
PYROSETTA_FLAGS = "-ex1 -ex2 -use_input_sc -relax:default_repeats 5"


def setup_logger():
    """Console + file logger. Safe to call in each process."""
    logger = logging.getLogger("fastrelax")
    if logger.handlers:
        return logger
    logger.setLevel(logging.INFO)
    fmt = logging.Formatter(
        "%(asctime)s [pid %(process)d] %(levelname)s %(message)s",
        datefmt="%H:%M:%S",
    )
    ch = logging.StreamHandler(sys.stdout)
    ch.setFormatter(fmt)
    logger.addHandler(ch)
    fh = logging.FileHandler(LOGFILE)
    fh.setFormatter(fmt)
    logger.addHandler(fh)
    return logger


# ---- per-worker global state (initialized once per process) ----
_SCOREFXN = None
_LOG = None


def _worker_init():
    """Runs once per worker process: init PyRosetta + score function."""
    global _SCOREFXN, _LOG
    from pyrosetta import init
    from pyrosetta.rosetta.core.scoring import get_score_function
    init(PYROSETTA_FLAGS)
    _SCOREFXN = get_score_function()   # ref2015
    _LOG = setup_logger()


def relax_one(pdb):
    """Relax a single PDB. Returns a summary row (list) or None."""
    from pyrosetta import pose_from_pdb
    from pyrosetta.rosetta.protocols.relax import FastRelax
    from pyrosetta.rosetta.core.scoring import CA_rmsd

    name = os.path.splitext(os.path.basename(pdb))[0]
    out_pdb = os.path.join(OUT_DIR, f"{name}_relaxed.pdb")

    # overwrite: always process, no resume-skip

    try:
        pose = pose_from_pdb(pdb)
    except Exception as e:
        _LOG.error(f"[fail] {name}: load error: {e}")
        return [name, "NA", "NA", "NA", "NA", f"load_error:{e}"]

    nres = pose.total_residue()
    start = pose.clone()
    score_before = _SCOREFXN(pose)

    relax = FastRelax()
    relax.set_scorefxn(_SCOREFXN)
    _LOG.info(f"[start] {name} nres={nres} score_before={score_before:.1f}")
    try:
        relax.apply(pose)
    except Exception as e:
        _LOG.error(f"[fail] {name}: relax error: {e}")
        return [name, nres, f"{score_before:.2f}", "NA", "NA", f"relax_error:{e}"]

    score_after = _SCOREFXN(pose)
    rmsd = CA_rmsd(start, pose)
    per_res = score_after / nres
    pose.dump_pdb(out_pdb)

    _LOG.info(f"[ok] {name}  before={score_before:.1f} after={score_after:.1f} "
              f"rmsd={rmsd:.2f} per_res={per_res:.2f}")
    return [name, nres, f"{score_before:.2f}", f"{score_after:.2f}",
            f"{rmsd:.3f}", f"{per_res:.3f}"]


def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    log = setup_logger()

    if len(sys.argv) > 1:
        n_workers = int(sys.argv[1])
    else:
        n_workers = int(os.environ.get("SLURM_CPUS_PER_TASK", 0)) or mp.cpu_count()

    pdbs = sorted(glob.glob(os.path.join(IN_DIR, "*.pdb")))
    if not pdbs:
        log.error(f"no PDBs found in {IN_DIR}")
        sys.exit(1)
    n_workers = max(1, min(n_workers, len(pdbs)))

    log.info(f"=== FastRelax run {datetime.now():%Y-%m-%d %H:%M:%S} ===")
    log.info(f"input: {IN_DIR}")
    log.info(f"{len(pdbs)} PDBs found | using {n_workers} workers | OVERWRITE mode")

    rows = []
    ctx = mp.get_context("spawn")
    with ctx.Pool(processes=n_workers, initializer=_worker_init) as pool:
        for res in pool.imap_unordered(relax_one, pdbs):
            if res is not None:
                rows.append(res)

    # overwrite summary TSV (mode 'w', always write header)
    with open(SUMMARY, "w", newline="") as f:
        w = csv.writer(f, delimiter="\t")
        w.writerow(["name", "n_res", "score_before",
                    "score_after", "ca_rmsd", "score_per_res"])
        w.writerows(rows)

    log.info(f"[done] {len(rows)} processed | summary -> {SUMMARY}")


if __name__ == "__main__":
    main()
