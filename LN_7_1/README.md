# LN_7_1：Graph Coloring → DIMACS → MiniSat 實驗

將隨機／結構化圖轉成 **k-coloring** CNF，以 **MiniSat** 求解，彙整為 `results.csv`，並繪製六張分析圖至 `figures/`。

## 環境需求

| 項目 | 說明 |
|------|------|
| **Python 3** | `python3` |
| **MiniSat** | 可在 `PATH` 找到 `minisat`，或以 `run_minisat_experiments.py --minisat /path/to/minisat` 指定 |
| **繪圖** | `pandas`、`matplotlib`、`seaborn`、`numpy` |

建議 Conda：

```bash
conda env create -f environment.yml
conda activate socv_ln71_plots
```

## 一鍵流程

於 **本目錄**執行：

```bash
chmod +x run.sh   # 首次需要時
./run.sh
```

`run.sh` 會：

1. 刪除 `graphs/`、`cnfs/`、`results.csv`、`raw_outputs/`、`.minisat_tmp/`、**`figures/`**
2. 批次產圖 → 轉 DIMACS → 跑 MiniSat → 寫 `results.csv`（含 `--save-raw`）
3. 呼叫 `plot_results.py` 重建 `figures/` 下六張 PNG

未啟用含 seaborn 的環境時，MiniSat 以前步驟仍可完成；繪圖會失敗。

## 實驗設計（`gen_all_graphs.py`）

細節以程式常數為準（下表與目前 `DENSITY_*`、`seeds` 設定一致）。

| 實驗 | CSV `experiment` | 目的 | graph type | \(n\) | \(k\) | density | seed | 預期觀察 |
|:-----|:-----------------|:-----|:-----------|:------|:------|:--------|:-----|:---------|
| **A** | `A_density` | 密度（sparse / dense）效應 | `random` | 60 | 3 | 0.03～0.13（含端點均分 **21** 點） | 1～40 | sparse / dense 對 **runtime**、**conflicts**；SAT／UNSAT **transition** 附近可能較難 |
| **B** | `B_size` | 問題規模 scaling | `random` | 20, 40, 60, 80 | 3 | **0.07** | 1～40 | **`#vars`、`#clauses`** 隨 \(n\) 增大時 **runtime / conflicts**（未必線性） |
| **C1** | `C_sat_unsat` | 保證可著色（SAT） | `planted_sat` | 60 | 3 | **0.07** | 1～40 | **保證 SAT**，著色搜尋成本 |
| **C2** | `C_sat_unsat` | 保證不可 \(k\)-著色（UNSAT） | `clique_unsat` | 60 | 3 | **0.07** | 1～40 | **保證 UNSAT**（嵌入 \(K_{k+1}\)），證明無解成本（未必較慢） |
| **C3** | `C_sat_unsat` | 與 C1/C2 對照 | `random` | 60 | 3 | **0.07** | 1～40 | 一般隨機 baseline，與 **C1/C2** 對照 |
| **D** | `D_colors` | 顏色數 \(k\) 效應 | `random` | 60 | 2, 3, 4, 5 | **0.07** | 1～40 | \(k\) 增大：**CNF 變大** 與 **較易著色** 的 tradeoff；**runtime** 未必單調 |

**C1～C3** 的 `experiment` 皆為 `C_sat_unsat`，以 **`graph_type`** 區分。題目若將 density 掃描稱為「Experiment B」，本作業 CSV 仍為 **`A_density`**（掃描）與 **`B_size`**（規模）。若修改 `gen_all_graphs.py` 的 `seeds`，請同步更新上表 seed 欄。

## 主要檔案

| 檔案 | 用途 |
|------|------|
| `run.sh` | 端到端 pipeline |
| `gen_graph.py` | 單一圖檔輸出（stdout） |
| `gen_all_graphs.py` | 批次寫入 `graphs/` |
| `graph_to_dimacs.py` | stdin 圖文字 → stdout DIMACS |
| `run_minisat_experiments.py` | 對 `cnfs/*.cnf` 跑 MiniSat → CSV |
| `plot_results.py` | `results.csv` → `figures/fig1`～`fig6` |
| `pack_bundle.sh` | 交作業用：程式 + README + 測資／結果 → zip |
| `environment.yml` | Conda 環境 `socv_ln71_plots` |

## 作業繳交（打包 zip）

於本目錄執行（建議先完成 `./run.sh`，以便 zip 內含完整測資與圖表）：

```bash
chmod +x pack_bundle.sh    # 首次需要時
./pack_bundle.sh           # 預設產生 LN_7_1_bundle_時間戳.zip
./pack_bundle.sh -o ~/Desktop/LN_7_1_submit.zip
./pack_bundle.sh --no-raw -o LN_7_1_light.zip   # 略過 raw_outputs，體積較小
```

解壓後會得到 **`LN_7_1_bundle/`**，內含：

- **程式與文件**：`README.md`、所有主要 `.py`、`run.sh`、`pack_bundle.sh`、`environment.yml`、`.gitignore`（有則複製）
- **實驗產物**（若已產生）：`graphs/`、`cnfs/`、`results.csv`、`figures/`、`raw_outputs/`
- **`MANIFEST.txt`**：打包時間與檔案清單

僅程式、尚未跑實驗時仍可打包，腳本會提示缺少測資／結果。

### `plot_results.py` 參數

```text
--csv results.csv
--out-dir figures
--dpi 200
--sat-ratio-denominator all | finished   # Fig.3 SAT ratio 分母
```

繪圖風格：**Fig.2、4、5、6** 為散佈圖（必要時軸上輕微 jitter）；**Fig.3** 為折線加圓點（聚合後的 SAT ratio）；**Fig.1** 為 `num_clauses` vs runtime，全部實驗一張圖，`hue=result`、`style=experiment`。

### MiniSat（`run_minisat_experiments.py`）

| 參數 | `run.sh` 設定 |
|------|----------------|
| `--timeout` | `30`（秒） |

## 輸出

| 路徑 | 內容 |
|------|------|
| `graphs/` | 圖檔文字 |
| `cnfs/` | `.cnf` |
| `results.csv` | 每案例一列（實驗、圖種類、`n`、`k`、density、seed、子句數、結果、時間、conflicts 等） |
| `raw_outputs/` | MiniSat log（`--save-raw`） |
| `figures/` | `fig1_runtime_vs_clauses.png` … `fig6_runtime_vs_k.png` |

## 僅重繪圖

```bash
conda activate socv_ln71_plots
python3 plot_results.py --csv results.csv --out-dir figures
```
