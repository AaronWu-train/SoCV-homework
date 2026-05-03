#!/usr/bin/env python3
import sys


def var_id(v: int, c: int, k: int) -> int:
    """
    x_{v,c} -> DIMACS variable id
    v: 1-based vertex index
    c: 1-based color index
    """
    return (v - 1) * k + c


def graph_coloring_to_cnf(n: int, m: int, k: int, edges: list[tuple[int, int]]):
    clauses = []

    # 1. 每個 vertex 至少有一個 color
    for v in range(1, n + 1):
        clauses.append([var_id(v, c, k) for c in range(1, k + 1)])

    # 2. 每個 vertex 至多有一個 color
    for v in range(1, n + 1):
        for c1 in range(1, k + 1):
            for c2 in range(c1 + 1, k + 1):
                clauses.append([
                    -var_id(v, c1, k),
                    -var_id(v, c2, k),
                ])

    # 3. 相鄰 vertices 不能同色
    for u, v in edges:
        for c in range(1, k + 1):
            clauses.append([
                -var_id(u, c, k),
                -var_id(v, c, k),
            ])

    return n * k, clauses


def main():
    data = sys.stdin.read().strip().split()

    if not data:
        print("Error: empty input", file=sys.stderr)
        sys.exit(1)

    ptr = 0
    n = int(data[ptr])
    ptr += 1

    m = int(data[ptr])
    ptr += 1

    k = int(data[ptr])
    ptr += 1

    edges = []

    for _ in range(m):
        if ptr + 1 >= len(data):
            print("Error: not enough edge data", file=sys.stderr)
            sys.exit(1)

        u = int(data[ptr])
        v = int(data[ptr + 1])
        ptr += 2

        edges.append((u, v))

    num_vars, clauses = graph_coloring_to_cnf(n, m, k, edges)

    print(f"p cnf {num_vars} {len(clauses)}")

    for clause in clauses:
        print(" ".join(map(str, clause)) + " 0")


if __name__ == "__main__":
    main()