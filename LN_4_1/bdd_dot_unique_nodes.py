#!/usr/bin/env python3
"""
從 gv BDRAW 產生的 .dot 檔擷取節點指標（"0x........"），用於跨多個 PO 的聯集去重計數。

同一輪 gv（同一個 BSETOrder / 同一批輸出）裡，共用的 BDD 節點會在 .dot 裡出現相同 0x id；
若比較不同 order 的 .dot（腳本每次重啟 gv），指標位址通常不同，聯集僅對「同一輪」有意義。

用法範例：
  python3 bdd_dot_unique_nodes.py mult4_out/*_File.dot
  python3 bdd_dot_unique_nodes.py --per-file adder8_out/*_DFS.dot
  python3 bdd_dot_unique_nodes.py --json mult4_out/mult_4_po*_File.dot
"""

from __future__ import annotations

import argparse
import glob
import json
import re
import sys
from pathlib import Path

# BDRAW 以 BddNodeVInt* 指標字串當 node 標籤
HEX_NODE_RE = re.compile(r'"0x[0-9a-fA-F]+"')


def extract_hex_ids(dot_text: str) -> set[str]:
    """回傳此 .dot 內出現過的所有 0x 指標字串（含引號內完整 token，統一成小寫 hex）。"""
    found = HEX_NODE_RE.findall(dot_text)
    return {s.strip('"').lower() for s in found}


def expand_paths(patterns: list[str]) -> list[Path]:
    paths: list[Path] = []
    for p in patterns:
        if any(ch in p for ch in "*?[]"):
            paths.extend(Path(x) for x in sorted(glob.glob(p)))
        else:
            paths.append(Path(p))
    # 唯一、只保留檔案
    seen: set[Path] = set()
    out: list[Path] = []
    for path in paths:
        rp = path.resolve()
        if rp in seen:
            continue
        seen.add(rp)
        if path.is_file():
            out.append(path)
    return out


def main() -> int:
    ap = argparse.ArgumentParser(description="統計 .dot 內 BDD 節點 0x id（跨檔聯集去重）")
    ap.add_argument(
        "paths",
        nargs="+",
        help="一或多個 .dot 路徑，或含萬用字元的 pattern（請加引號）",
    )
    ap.add_argument(
        "--per-file",
        action="store_true",
        help="列出每個檔案各自的 unique 0x 個數",
    )
    ap.add_argument(
        "--json",
        action="store_true",
        help="以 JSON 印出（含聯集與可選的 per-file）",
    )
    args = ap.parse_args()

    files = expand_paths(args.paths)
    if not files:
        print("沒有找到任何檔案。", file=sys.stderr)
        return 1

    per_file: dict[str, set[str]] = {}
    union: set[str] = set()
    for f in files:
        try:
            text = f.read_text(encoding="utf-8", errors="replace")
        except OSError as e:
            print(f"無法讀取 {f}: {e}", file=sys.stderr)
            return 1
        ids = extract_hex_ids(text)
        per_file[str(f)] = ids
        union |= ids

    if args.json:
        payload = {
            "file_count": len(files),
            "union_unique_hex_ids": len(union),
            "hex_ids": sorted(union),
        }
        if args.per_file:
            payload["per_file"] = {
                path: {"count": len(ids), "hex_ids": sorted(ids)}
                for path, ids in per_file.items()
            }
        print(json.dumps(payload, ensure_ascii=False, indent=2))
        return 0

    if args.per_file:
        for path, ids in per_file.items():
            print(f"{len(ids):6d}  {path}")
        print("------")
    print(f"聯集 unique 0x 節點數（跨上述 {len(files)} 個檔）: {len(union)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
