#!/usr/bin/env bash
# 以 gv 對 Verilog 做 BDD：依序嘗試 BSETOrder 的四種模式，並對每個 PO（gate id）輸出 BDRAW 的 .dot。
#
# 注意：gv 的 BSETOrder 在同一個行程內只能設定一次，因此本腳本會啟動多次 gv。
#
# 用法：
#   ./gv_bdd_draw_all_orders.sh [adder_4.v]
# 環境變數：
#   GV      Ric gv 執行檔路徑
#   DOT     Graphviz 的 dot（預設：PATH 中的 dot），用於 .dot → .png
#   OUTDIR  輸出目錄（預設：腳本所在目錄）
#   PNG_DPI PNG 解析度（預設：150）

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# 預設把 .dot 寫在腳本目錄，避免從其他 cwd 執行時檔案散落到錯誤路徑
OUTDIR="${OUTDIR:-$SCRIPT_DIR}"
VERILOG="${1:-"$SCRIPT_DIR/adder_4.v"}"
DOT_BIN="${DOT:-dot}"
PNG_DPI="${PNG_DPI:-150}"

# 預設優先使用 SoCV 專案內建出的 gv（避免與 Graphviz 的 gv 指令衝突）
GV_BIN="${GV:-}"
if [[ -z "$GV_BIN" ]]; then
  for guess in \
    "$SCRIPT_DIR/../../gv/build/gv" \
    "$SCRIPT_DIR/../../gv/build/bin/gv"; do
    if [[ -x "$guess" ]]; then
      GV_BIN="$guess"
      break
    fi
  done
fi
GV_BIN="${GV_BIN:-gv}"

if [[ ! -f "$VERILOG" ]]; then
  echo "找不到 Verilog：$VERILOG" >&2
  exit 1
fi

if ! command -v "$GV_BIN" >/dev/null 2>&1 && [[ ! -x "$GV_BIN" ]]; then
  echo "找不到可執行的 gv（請設定 GV 指向 Ric gv 的執行檔，勿使用 Graphviz 的 gv）：$GV_BIN" >&2
  exit 1
fi

SKIP_PNG=0
if ! command -v "$DOT_BIN" >/dev/null 2>&1 && [[ ! -x "$DOT_BIN" ]]; then
  echo "警告：找不到 $DOT_BIN，將略過 .dot 轉 .png（請安裝 Graphviz 或設定 DOT）。" >&2
  SKIP_PNG=1
fi

ABS_VERILOG="$(cd "$(dirname "$VERILOG")" && pwd)/$(basename "$VERILOG")"
mkdir -p "$OUTDIR"
ABS_OUTDIR="$(cd "$OUTDIR" && pwd)"

WORKDIR="$(mktemp -d "${TMPDIR:-/tmp}/gv_bdd_draw.XXXXXX")"
cleanup() { rm -rf "$WORKDIR"; }
trap cleanup EXIT

# --- 1) 讀電路並列出 PO gate id（與 BDRAW 用的 bddName 一致）---
PROBE_DOF="$WORKDIR/probe.dof"
cat >"$PROBE_DOF" <<EOF
cirr $ABS_VERILOG
cirp -po
q -f
EOF

PROBE_LOG="$WORKDIR/probe.log"
"$GV_BIN" -File "$PROBE_DOF" >"$PROBE_LOG" 2>&1 || true

PO_LINE="$(grep 'POs of the circuit:' "$PROBE_LOG" | tail -n1 || true)"
if [[ -z "$PO_LINE" ]]; then
  echo "無法從 gv 輸出解析 PO 列表。請確認 cirr / cirp 是否正確。完整 log：" >&2
  cat "$PROBE_LOG" >&2
  exit 1
fi

# 取出 gate id 數字列表
read -r -a PO_IDS <<<"${PO_LINE#*POs of the circuit:}"
if [[ ${#PO_IDS[@]} -eq 0 ]]; then
  echo "PO 列表為空：$PO_LINE" >&2
  exit 1
fi

echo "PO gate ids: ${PO_IDS[*]}"

STEM="$(basename "$VERILOG" .v)"
SUMMARY_TSV="$ABS_OUTDIR/${STEM}_bdd_experiment_summary.tsv"

# --- 2) 四種變數順序各跑一輪 gv ---
# shellcheck disable=SC2206
ORDERS=( "-File" "-RFile" "-DFS" "-RDFS" )

{
  printf '%s\t%s\t%s\t%s\n' "order" "po_gate_id" "bdd_nodes" "dot_png"
} >"$SUMMARY_TSV"

for ord in "${ORDERS[@]}"; do
  tag="${ord#-}" # File, RFile, DFS, RDFS
  DOF="$WORKDIR/run_${tag}.dof"
  RUN_LOG="$WORKDIR/run_${tag}.log"
  STATS_TXT="$ABS_OUTDIR/${STEM}_bdd_nodes_${tag}.txt"
  {
    echo "cirr $ABS_VERILOG"
    echo "bsetorder $ord"
    echo "bcons -all"
    for id in "${PO_IDS[@]}"; do
      out="$ABS_OUTDIR/${STEM}_po${id}_${tag}.dot"
      echo "bdraw $id $out"
      # brep 會印出「==> Total #BddNodeVs : N」（該 PO 根節點 BDD 圖上的節點數，共用子圖只算一次）
      echo "brep $id"
    done
    echo "q -f"
  } >"$DOF"

  echo "=== BSETOrder $ord ==="
  "$GV_BIN" -File "$DOF" >"$RUN_LOG" 2>&1

  mapfile -t NODE_COUNTS < <(grep '==> Total #BddNodeVs :' "$RUN_LOG" | sed 's/.*: //' | tr -d '\r')
  if [[ ${#NODE_COUNTS[@]} -ne ${#PO_IDS[@]} ]]; then
    echo "警告：無法從 log 對齊 brep 節點數（預期 ${#PO_IDS[@]} 筆，實際 ${#NODE_COUNTS[@]}）。請檢查：$RUN_LOG" >&2
  fi

  sum=0
  {
    echo "# BSETOrder $ord"
    echo "# Verilog: $ABS_VERILOG"
    echo "# 各欄為該 PO 之 BDD 根節點展開後的 BddNodeV 個數（brep 輸出之 Total #BddNodeVs）"
    echo "# 加總為各 PO 數字相加；若多個 PO 共用子結構，整個 manager 實體節點數通常小於加總。"
    echo ""
    for i in "${!PO_IDS[@]}"; do
      id="${PO_IDS[i]}"
      n="${NODE_COUNTS[i]:-?}"
      echo "PO gate $id : $n"
      if [[ "$n" =~ ^[0-9]+$ ]]; then
        sum=$((sum + n))
      fi
    done
    echo ""
    echo "SUM_PO_BDD_NODE_COUNTS $sum"
  } >"$STATS_TXT"

  for i in "${!PO_IDS[@]}"; do
    id="${PO_IDS[i]}"
    n="${NODE_COUNTS[i]:-}"
    dotf="$ABS_OUTDIR/${STEM}_po${id}_${tag}.dot"
    pngf="${dotf%.dot}.png"
    if [[ -n "$n" ]]; then
      printf '%s\t%s\t%s\t%s\n' "$tag" "$id" "$n" "$(basename "$pngf")" >>"$SUMMARY_TSV"
    fi
  done

  if [[ "$SKIP_PNG" -eq 0 ]]; then
    shopt -s nullglob
    for dotf in "$ABS_OUTDIR/${STEM}_po"*"_${tag}.dot"; do
      [[ -f "$dotf" ]] || continue
      "$DOT_BIN" -Tpng "-Gdpi=$PNG_DPI" "$dotf" -o "${dotf%.dot}.png"
    done
    shopt -u nullglob
  fi
done

echo "完成。輸出目錄：$ABS_OUTDIR"
echo "彙總表（TSV）：$SUMMARY_TSV"
