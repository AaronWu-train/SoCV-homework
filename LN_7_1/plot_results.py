#!/usr/bin/env python3
"""
Plot MiniSat experiment outputs from results.csv.

Conda:
  conda env create -f environment.yml
  conda activate socv_ln71_plots
  python plot_results.py

Or using pip: pip install pandas matplotlib seaborn

Note on experiment IDs (CSV column `experiment`):
  - Density sweep (sparse/dense): A_density
  - Size scaling: B_size
  - Graph-type SAT/UNSAT: C_sat_unsat
  - Colors k: D_colors
"""

from __future__ import annotations

import argparse
from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import seaborn as sns


NUMERIC_COLS = (
    "wall_time_sec",
    "num_clauses",
    "density",
    "conflicts",
    "k",
)


def load_and_clean(csv_path: Path) -> pd.DataFrame:
    df = pd.read_csv(csv_path)
    for col in NUMERIC_COLS:
        if col in df.columns:
            df[col] = pd.to_numeric(df[col], errors="coerce")
    return df


def save_fig(path: Path, dpi: int) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    plt.tight_layout()
    plt.savefig(path, dpi=dpi, bbox_inches="tight")
    plt.close()


def _jitter(n: int, width: float, seed: int) -> np.ndarray:
    rng = np.random.default_rng(seed)
    return rng.uniform(-width, width, size=n)


def plot_fig1_runtime_vs_clauses(df: pd.DataFrame, out_path: Path, dpi: int) -> None:
    """All experiments: runtime vs clause count, colored by SAT/UNSAT/…"""
    plt.figure(figsize=(9, 5))
    sns.scatterplot(
        data=df,
        x="num_clauses",
        y="wall_time_sec",
        hue="result",
        alpha=0.55,
        style="experiment",
        s=28,
    )
    plt.xlabel("num_clauses")
    plt.ylabel("wall_time_sec")
    plt.title("Fig.1 Runtime vs number of clauses (all experiments)")
    save_fig(out_path, dpi)


def plot_fig2_runtime_vs_density(df_a: pd.DataFrame, out_path: Path, dpi: int) -> None:
    """Density sweep (A_density): one point per seed; slight x jitter for readability."""
    d = df_a.copy()
    d["_x"] = d["density"].astype(float) + _jitter(len(d), 0.0015 * (d["density"].max() - d["density"].min() + 1e-9), seed=2)
    plt.figure(figsize=(10, 5))
    sns.scatterplot(
        data=d,
        x="_x",
        y="wall_time_sec",
        hue="result",
        alpha=0.65,
        s=22,
    )
    plt.xlabel("density")
    plt.ylabel("wall_time_sec")
    plt.title("Fig.2 Runtime vs density (A_density; scatter per seed)")
    plt.legend(bbox_to_anchor=(1.02, 1), loc="upper left")
    save_fig(out_path, dpi)


def plot_fig3_sat_ratio_vs_density(
    df_a: pd.DataFrame,
    out_path: Path,
    dpi: int,
    sat_ratio_denominator: str,
) -> None:
    """SAT ratio per density."""

    def ratio(group: pd.DataFrame) -> float:
        if sat_ratio_denominator == "finished":
            mask = group["result"].isin(("SAT", "UNSAT"))
            g = group.loc[mask]
            if len(g) == 0:
                return float("nan")
            return (g["result"] == "SAT").sum() / len(g)
        return (group["result"] == "SAT").sum() / len(group)

    ratios = df_a.groupby("density", sort=True).apply(ratio).reset_index(name="SAT_ratio")

    plt.figure(figsize=(9, 4.5))
    # Line + markers reads clearer than lone scatter for aggregated SAT ratio vs density.
    sns.lineplot(
        data=ratios,
        x="density",
        y="SAT_ratio",
        marker="o",
        linewidth=2,
        legend=False,
    )
    plt.ylim(0, 1)
    plt.ylabel("SAT ratio")
    plt.xlabel("density")
    den_label = "all runs" if sat_ratio_denominator == "all" else "SAT+UNSAT only"
    plt.title(f"Fig.3 SAT ratio vs density (A_density; denominator={den_label})")
    save_fig(out_path, dpi)


def plot_fig4_conflicts_vs_density(df_a: pd.DataFrame, out_path: Path, dpi: int) -> None:
    df_plot = df_a.dropna(subset=["conflicts"]).copy()
    df_plot["_x"] = df_plot["density"].astype(float) + _jitter(
        len(df_plot),
        0.0015 * (df_plot["density"].max() - df_plot["density"].min() + 1e-9),
        seed=4,
    )
    plt.figure(figsize=(9, 5))
    sns.scatterplot(
        data=df_plot,
        x="_x",
        y="conflicts",
        hue="result",
        alpha=0.65,
        s=22,
    )
    plt.xlabel("density")
    plt.ylabel("conflicts")
    n_drop = len(df_a) - len(df_plot)
    extra = f" ({n_drop} rows without conflicts omitted)" if n_drop else ""
    plt.title(f"Fig.4 Conflicts vs density (A_density){extra}")
    plt.legend(bbox_to_anchor=(1.02, 1), loc="upper left")
    save_fig(out_path, dpi)


def plot_fig5_runtime_by_graph_type(df_c: pd.DataFrame, out_path: Path, dpi: int) -> None:
    order = ["planted_sat", "clique_unsat", "random"]
    d = df_c.copy()
    d["graph_type"] = pd.Categorical(d["graph_type"], categories=order, ordered=True)
    codes = d["graph_type"].cat.codes.astype(float)
    d["_x"] = codes + _jitter(len(d), 0.22, seed=5)
    plt.figure(figsize=(8, 5))
    sns.scatterplot(
        data=d,
        x="_x",
        y="wall_time_sec",
        hue="result",
        style="graph_type",
        alpha=0.65,
        s=28,
    )
    plt.xlabel("graph_type")
    plt.ylabel("wall_time_sec")
    plt.title("Fig.5 Runtime by graph type (C_sat_unsat)")
    plt.xticks(range(len(order)), order, rotation=15, ha="right")
    plt.legend(bbox_to_anchor=(1.02, 1), loc="upper left")
    plt.xlim(-0.6, len(order) - 0.4)
    save_fig(out_path, dpi)


def plot_fig6_runtime_vs_k(df_d: pd.DataFrame, out_path: Path, dpi: int) -> None:
    d = df_d.copy()
    d["_x"] = d["k"].astype(float) + _jitter(len(d), 0.18, seed=6)
    plt.figure(figsize=(9, 5))
    sns.scatterplot(
        data=d,
        x="_x",
        y="wall_time_sec",
        hue="result",
        alpha=0.65,
        s=26,
    )
    plt.xlabel("k (colors)")
    plt.ylabel("wall_time_sec")
    plt.title("Fig.6 Runtime vs k (D_colors)")
    ks = sorted(d["k"].dropna().unique())
    if ks:
        plt.xticks(ks)
        plt.xlim(min(ks) - 0.5, max(ks) + 0.5)
    plt.legend(title="result", bbox_to_anchor=(1.02, 1), loc="upper left")
    save_fig(out_path, dpi)


def main() -> None:
    parser = argparse.ArgumentParser(description="Plot MiniSat CSV results (6 figures).")
    parser.add_argument("--csv", type=Path, default=Path("results.csv"))
    parser.add_argument("--out-dir", type=Path, default=Path("figures"))
    parser.add_argument("--dpi", type=int, default=200)
    parser.add_argument(
        "--sat-ratio-denominator",
        choices=("all", "finished"),
        default="all",
        help="Fig.3: 'all' counts every row per density; 'finished' uses only SAT/UNSAT rows.",
    )
    args = parser.parse_args()

    sns.set_theme(style="whitegrid")

    df = load_and_clean(args.csv)
    df_a = df[df["experiment"] == "A_density"].copy()
    df_c = df[df["experiment"] == "C_sat_unsat"].copy()
    df_d = df[df["experiment"] == "D_colors"].copy()

    out = args.out_dir
    plot_fig1_runtime_vs_clauses(df, out / "fig1_runtime_vs_clauses.png", args.dpi)
    plot_fig2_runtime_vs_density(df_a, out / "fig2_runtime_vs_density.png", args.dpi)
    plot_fig3_sat_ratio_vs_density(
        df_a,
        out / "fig3_sat_ratio_vs_density.png",
        args.dpi,
        args.sat_ratio_denominator,
    )
    plot_fig4_conflicts_vs_density(df_a, out / "fig4_conflicts_vs_density.png", args.dpi)
    plot_fig5_runtime_by_graph_type(df_c, out / "fig5_runtime_by_graph_type.png", args.dpi)
    plot_fig6_runtime_vs_k(df_d, out / "fig6_runtime_vs_k.png", args.dpi)

    print(f"Wrote figures to {out.resolve()}")


if __name__ == "__main__":
    main()
