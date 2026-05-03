#!/usr/bin/env bash
# 交作業用：程式 + README + 測資／結果 打成 zip（見 README「作業繳交」）。

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

print_usage() {
    cat <<'EOF'
將下列項目複製到暫存目錄 LN_7_1_bundle/ 後打成 zip：
  • 必含（若檔案存在）：README.md、所有主要 .py、run.sh、pack_bundle.sh、
    environment.yml、.gitignore
  • 若有跑過 pipeline：graphs/、cnfs/、results.csv、figures/、raw_outputs/

解壓後頂層為 LN_7_1_bundle/，內含 MANIFEST.txt（檔案清單）。

選項：
  -o, --output PATH    輸出 zip 路徑（預設：./LN_7_1_bundle_YYYYMMDD_HHMMSS.zip）
  --no-raw             不要打包 raw_outputs/
  -h, --help           顯示說明

範例：
  ./pack_bundle.sh
  ./pack_bundle.sh -o ~/Desktop/socv_ln71_submit.zip
  ./pack_bundle.sh --no-raw -o bundle_small.zip
EOF
}

OUTPUT=""
NO_RAW=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        -o|--output)
            OUTPUT="$2"
            shift 2
            ;;
        --no-raw)
            NO_RAW=true
            shift
            ;;
        -h|--help)
            print_usage
            exit 0
            ;;
        *)
            echo "未知參數: $1" >&2
            print_usage >&2
            exit 2
            ;;
    esac
done

if [[ -z "$OUTPUT" ]]; then
    OUTPUT="${ROOT}/LN_7_1_bundle_$(date +%Y%m%d_%H%M%S).zip"
elif [[ "$OUTPUT" != /* ]]; then
    OUTPUT="${ROOT}/${OUTPUT}"
fi

CANDIDATES=(graphs cnfs results.csv figures)
if [[ "$NO_RAW" == false ]]; then
    CANDIDATES+=(raw_outputs)
fi

ITEMS=()
for path in "${CANDIDATES[@]}"; do
    if [[ -e "$path" ]]; then
        ITEMS+=("$path")
    fi
done

CODE_FILES=(
    README.md
    environment.yml
    .gitignore
    run.sh
    pack_bundle.sh
    gen_graph.py
    gen_all_graphs.py
    graph_to_dimacs.py
    run_minisat_experiments.py
    plot_results.py
)

STAGING="$(mktemp -d)"
trap 'rm -rf "$STAGING"' EXIT

BUNDLE_NAME="LN_7_1_bundle"
DEST="$STAGING/$BUNDLE_NAME"
mkdir -p "$DEST"

CODE_COPIED=0
for f in "${CODE_FILES[@]}"; do
    if [[ -f "$f" ]]; then
        cp "$f" "$DEST/"
        CODE_COPIED=$((CODE_COPIED + 1))
    fi
done

if [[ "$CODE_COPIED" -eq 0 ]]; then
    echo "錯誤：找不到 README 或程式檔（請在 LN_7_1 目錄執行）。" >&2
    exit 1
fi

for path in "${ITEMS[@]}"; do
    cp -R "$path" "$DEST/"
done

if [[ ${#ITEMS[@]} -eq 0 ]]; then
    echo "警告：未找到測資或結果（graphs/、cnfs/ 等）。請先 ./run.sh 再打包以交出完整實驗。" >&2
fi

{
    echo "Packed at $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo "Source directory: $ROOT"
    echo "Contents:"
    (cd "$DEST" && find . -type f | sort)
} >"$DEST/MANIFEST.txt"

mkdir -p "$(dirname "$OUTPUT")"
rm -f "$OUTPUT"
(cd "$STAGING" && zip -rq "$OUTPUT" "$BUNDLE_NAME")

echo "已建立：$OUTPUT"
echo "程式與說明：${CODE_COPIED} 個檔案"
if [[ ${#ITEMS[@]} -gt 0 ]]; then
    echo "測資／結果：$(printf '%s ' "${ITEMS[@]}")"
fi
