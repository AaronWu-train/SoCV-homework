#!/usr/bin/env python3
import argparse
import random
from itertools import combinations


def max_num_edges(n: int) -> int:
    return n * (n - 1) // 2


def density_to_m(n: int, density: float) -> int:
    return round(density * max_num_edges(n))


def gen_random_graph(n: int, m: int):
    all_edges = list(combinations(range(1, n + 1), 2))
    edges = random.sample(all_edges, m)
    return sorted(edges)


def gen_planted_sat_graph(n: int, m: int, k: int):
    """
    保證 k-colorable：
    先把 vertices 分到 k 個 groups，只在不同 group 之間加 edge。
    """
    groups = [[] for _ in range(k)]

    vertices = list(range(1, n + 1))
    random.shuffle(vertices)

    for i, v in enumerate(vertices):
        groups[i % k].append(v)

    color_of = {}
    for color, group in enumerate(groups):
        for v in group:
            color_of[v] = color

    possible_edges = []

    for u, v in combinations(range(1, n + 1), 2):
        if color_of[u] != color_of[v]:
            possible_edges.append((u, v))

    if m > len(possible_edges):
        raise ValueError(
            f"m = {m} is too large for planted_sat graph. "
            f"Maximum allowed edges = {len(possible_edges)}"
        )

    edges = random.sample(possible_edges, m)
    return sorted(edges)


def gen_clique_unsat_graph(n: int, m: int, k: int):
    """
    保證 not k-colorable：
    強制放入 K_{k+1} clique。
    因為 K_{k+1} 至少需要 k+1 種顏色，所以用 k colors 一定 UNSAT。
    """
    if n < k + 1:
        raise ValueError("Need n >= k + 1 for clique_unsat graph.")

    clique_vertices = list(range(1, k + 2))
    required_edges = set(combinations(clique_vertices, 2))

    if m < len(required_edges):
        raise ValueError(
            f"m = {m} is too small for clique_unsat graph. "
            f"Need at least {len(required_edges)} edges for K_{k + 1}."
        )

    all_edges = set(combinations(range(1, n + 1), 2))
    remaining_edges = list(all_edges - required_edges)

    extra_count = m - len(required_edges)
    extra_edges = random.sample(remaining_edges, extra_count)

    edges = list(required_edges) + extra_edges
    return sorted(edges)


def main():
    parser = argparse.ArgumentParser(
        description="Generate graph coloring testcase."
    )

    parser.add_argument("--type", required=True,
                        choices=["random", "planted_sat", "clique_unsat"])
    parser.add_argument("--n", type=int, required=True)
    parser.add_argument("--k", type=int, required=True)
    parser.add_argument("--density", type=float, default=None)
    parser.add_argument("--m", type=int, default=None)
    parser.add_argument("--seed", type=int, default=None)

    args = parser.parse_args()

    if args.seed is not None:
        random.seed(args.seed)

    n = args.n
    k = args.k

    if args.m is not None:
        m = args.m
    else:
        if args.density is None:
            raise ValueError("Either --m or --density must be provided.")
        if not (0 <= args.density <= 1):
            raise ValueError("density must be between 0 and 1.")
        m = density_to_m(n, args.density)

    if m > max_num_edges(n):
        raise ValueError(f"m = {m} exceeds maximum edge count {max_num_edges(n)}.")

    if args.type == "random":
        edges = gen_random_graph(n, m)
    elif args.type == "planted_sat":
        edges = gen_planted_sat_graph(n, m, k)
    elif args.type == "clique_unsat":
        edges = gen_clique_unsat_graph(n, m, k)
    else:
        raise ValueError(f"Unknown graph type: {args.type}")

    print(n, len(edges), k)

    for u, v in edges:
        print(u, v)


if __name__ == "__main__":
    main()
    