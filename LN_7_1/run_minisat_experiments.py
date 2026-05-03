#!/usr/bin/env python3
import argparse
import csv
import os
import re
import subprocess
import time
from pathlib import Path


def parse_dimacs_header(cnf_path: Path):
    """
    Read p cnf <num_vars> <num_clauses>.
    """
    with open(cnf_path, "r") as f:
        for line in f:
            line = line.strip()
            if line.startswith("p cnf"):
                parts = line.split()
                return int(parts[2]), int(parts[3])

    raise ValueError(f"No DIMACS header found in {cnf_path}")


def parse_case_name(cnf_path: Path):
    """
    Parse filename like:
      A_density_random_n60_k3_d0p07_s3.cnf
      B_size_random_n20_k3_d0p05_s1.cnf
      C_sat_unsat_clique_unsat_n60_k3_d0p4_s2.cnf
      D_colors_random_n60_k5_d0p4_s4.cnf
    """
    stem = cnf_path.stem

    pattern = re.compile(
        r"^(?P<experiment>.+?)_"
        r"(?P<graph_type>random|planted_sat|clique_unsat)_"
        r"n(?P<n>\d+)_"
        r"k(?P<k>\d+)_"
        r"d(?P<density>[0-9p]+)_"
        r"s(?P<seed>\d+)$"
    )

    match = pattern.match(stem)

    if not match:
        return {
            "case_id": stem,
            "experiment": "unknown",
            "graph_type": "unknown",
            "n": "",
            "k": "",
            "density": "",
            "seed": "",
        }

    info = match.groupdict()

    return {
        "case_id": stem,
        "experiment": info["experiment"],
        "graph_type": info["graph_type"],
        "n": int(info["n"]),
        "k": int(info["k"]),
        "density": float(info["density"].replace("p", ".")),
        "seed": int(info["seed"]),
    }


def parse_minisat_output(stdout: str, stderr: str):
    """
    MiniSat usually prints stats to stdout.
    Different builds may format lines slightly differently,
    so this parser is intentionally tolerant.
    """
    text = stdout + "\n" + stderr

    result = "UNKNOWN"
    conflicts = ""
    decisions = ""
    propagations = ""
    cpu_time_reported = ""

    for line in text.splitlines():
        stripped = line.strip()

        if stripped == "SATISFIABLE":
            result = "SAT"
        elif stripped == "UNSATISFIABLE":
            result = "UNSAT"
        elif stripped == "INDETERMINATE":
            result = "UNKNOWN"

        # examples:
        # conflicts             : 123
        # decisions             : 456
        # propagations          : 789
        # CPU time              : 0.01 s
        if stripped.startswith("conflicts"):
            conflicts = extract_first_int(stripped)

        elif stripped.startswith("decisions"):
            decisions = extract_first_int(stripped)

        elif stripped.startswith("propagations"):
            propagations = extract_first_int(stripped)

        elif stripped.startswith("CPU time"):
            cpu_time_reported = extract_first_float(stripped)

    return {
        "result": result,
        "conflicts": conflicts,
        "decisions": decisions,
        "propagations": propagations,
        "cpu_time_reported": cpu_time_reported,
        "raw_output": text,
    }


def extract_first_int(s: str):
    match = re.search(r"\d+", s)
    return int(match.group(0)) if match else ""


def extract_first_float(s: str):
    match = re.search(r"\d+(?:\.\d+)?", s)
    return float(match.group(0)) if match else ""


def run_minisat(minisat_bin: str, cnf_path: Path, tmp_out_path: Path, timeout: int | None):
    """
    Run:
      minisat input.cnf tmp_result.out

    We use a temporary output file because MiniSat writes assignment/result there.
    """
    cmd = [
        minisat_bin,
        str(cnf_path),
        str(tmp_out_path),
    ]

    start = time.perf_counter()

    try:
        completed = subprocess.run(
            cmd,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            timeout=timeout,
        )

        elapsed = time.perf_counter() - start

        parsed = parse_minisat_output(completed.stdout, completed.stderr)

        return {
            "returncode": completed.returncode,
            "wall_time": elapsed,
            **parsed,
        }

    except subprocess.TimeoutExpired as e:
        elapsed = time.perf_counter() - start

        stdout = e.stdout if e.stdout else ""
        stderr = e.stderr if e.stderr else ""

        return {
            "returncode": "TIMEOUT",
            "wall_time": elapsed,
            "result": "TIMEOUT",
            "conflicts": "",
            "decisions": "",
            "propagations": "",
            "cpu_time_reported": "",
            "raw_output": stdout + "\n" + stderr,
        }


def main():
    parser = argparse.ArgumentParser(
        description="Run MiniSat on CNF files and collect experiment results."
    )

    parser.add_argument(
        "--cnf-dir",
        default="cnfs",
        help="Directory containing .cnf files."
    )

    parser.add_argument(
        "--output",
        default="results.csv",
        help="Output CSV file."
    )

    parser.add_argument(
        "--minisat",
        default="minisat",
        help="Path to minisat binary."
    )

    parser.add_argument(
        "--timeout",
        type=int,
        default=None,
        help="Timeout per case in seconds."
    )

    parser.add_argument(
        "--save-raw",
        action="store_true",
        help="Save raw MiniSat output into raw_outputs/."
    )

    args = parser.parse_args()

    cnf_dir = Path(args.cnf_dir)
    output_csv = Path(args.output)

    cnf_files = sorted(cnf_dir.glob("*.cnf"))

    if not cnf_files:
        raise FileNotFoundError(f"No .cnf files found in {cnf_dir}")

    tmp_dir = Path(".minisat_tmp")
    tmp_dir.mkdir(exist_ok=True)

    raw_dir = Path("raw_outputs")
    if args.save_raw:
        raw_dir.mkdir(exist_ok=True)

    rows = []

    for idx, cnf_path in enumerate(cnf_files, start=1):
        print(f"[{idx}/{len(cnf_files)}] Running {cnf_path}")

        case_info = parse_case_name(cnf_path)
        num_vars, num_clauses = parse_dimacs_header(cnf_path)

        tmp_out_path = tmp_dir / f"{cnf_path.stem}.out"

        run_info = run_minisat(
            minisat_bin=args.minisat,
            cnf_path=cnf_path,
            tmp_out_path=tmp_out_path,
            timeout=args.timeout,
        )

        row = {
            **case_info,
            "num_vars": num_vars,
            "num_clauses": num_clauses,
            "result": run_info["result"],
            "wall_time_sec": f"{run_info['wall_time']:.6f}",
            "cpu_time_reported_sec": run_info["cpu_time_reported"],
            "conflicts": run_info["conflicts"],
            "decisions": run_info["decisions"],
            "propagations": run_info["propagations"],
            "returncode": run_info["returncode"],
            "cnf_file": str(cnf_path),
        }

        rows.append(row)

        if args.save_raw:
            raw_path = raw_dir / f"{cnf_path.stem}.log"
            with open(raw_path, "w") as f:
                f.write(run_info["raw_output"])

    fieldnames = [
        "case_id",
        "experiment",
        "graph_type",
        "n",
        "k",
        "density",
        "seed",
        "num_vars",
        "num_clauses",
        "result",
        "wall_time_sec",
        "cpu_time_reported_sec",
        "conflicts",
        "decisions",
        "propagations",
        "returncode",
        "cnf_file",
    ]

    with open(output_csv, "w", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)

    print()
    print(f"Done. Wrote results to {output_csv}")
    print(f"Total cases: {len(rows)}")


if __name__ == "__main__":
    main()