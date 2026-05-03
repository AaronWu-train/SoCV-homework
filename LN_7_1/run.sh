#!/usr/bin/env bash
rm -rf graphs cnfs results.csv raw_outputs .minisat_tmp figures
mkdir -p graphs cnfs

python3 gen_all_graphs.py

for f in graphs/*.txt; do
    base=$(basename "$f" .txt)
    python3 graph_to_dimacs.py < "$f" > "cnfs/${base}.cnf"
done

python3 run_minisat_experiments.py \
    --cnf-dir cnfs \
    --output results.csv \
    --timeout 30 \
    --save-raw

# 繪圖需 pandas / matplotlib / seaborn（可用 conda: environment.yml）
mkdir -p figures
python3 plot_results.py \
    --csv results.csv \
    --out-dir figures