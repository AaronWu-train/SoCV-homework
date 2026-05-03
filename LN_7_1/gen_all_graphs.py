#!/usr/bin/env python3
import os
import subprocess


OUT_DIR = "graphs"

# Experiment A: inclusive endpoints, evenly spaced
DENSITY_A_MIN = 0.03
DENSITY_A_MAX = 0.13
DENSITY_A_NUM_POINTS = 21


def run_gen(exp: str, graph_type: str, n: int, k: int, density: float, seed: int):
    density_tag = str(density).replace(".", "p")

    filename = (
        f"{exp}_"
        f"{graph_type}_"
        f"n{n}_"
        f"k{k}_"
        f"d{density_tag}_"
        f"s{seed}.txt"
    )

    output_path = os.path.join(OUT_DIR, filename)

    cmd = [
        "python3", "gen_graph.py",
        "--type", graph_type,
        "--n", str(n),
        "--k", str(k),
        "--density", str(density),
        "--seed", str(seed),
    ]

    with open(output_path, "w") as f:
        subprocess.run(cmd, stdout=f, check=True)

    print(f"Generated {output_path}")


def main():
    os.makedirs(OUT_DIR, exist_ok=True)

    seeds = range(1, 41)

    # Experiment A: density effect (runs first), 0.03 .. 0.13, 20 evenly spaced points
    span = DENSITY_A_MAX - DENSITY_A_MIN
    for i in range(DENSITY_A_NUM_POINTS):
        density = round(DENSITY_A_MIN + i * span / (DENSITY_A_NUM_POINTS - 1), 6)
        for seed in seeds:
            run_gen(
                exp="A_density",
                graph_type="random",
                n=60,
                k=3,
                density=density,
                seed=seed,
            )

    # Experiment B: problem size scaling
    for n in [20, 40, 60, 80]:
        for seed in seeds:
            run_gen(
                exp="B_size",
                graph_type="random",
                n=n,
                k=3,
                density=0.07,
                seed=seed,
            )

    # Experiment C: SAT vs UNSAT comparison
    for graph_type in ["planted_sat", "clique_unsat", "random"]:
        for seed in seeds:
            run_gen(
                exp="C_sat_unsat",
                graph_type=graph_type,
                n=60,
                k=3,
                density=0.07,
                seed=seed,
            )

    # Experiment D: number of colors effect
    for k in [2, 3, 4, 5]:
        for seed in seeds:
            run_gen(
                exp="D_colors",
                graph_type="random",
                n=60,
                k=k,
                density=0.07,
                seed=seed,
            )


if __name__ == "__main__":
    main()
