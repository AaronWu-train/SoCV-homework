# LN_8_2 販賣機 BDD 抽象驗證實驗摘要

## gv 用法（指令直接在 gv 裡打）

啟動（請用課程 Ric gv，不是 Graphviz 的 `gv`）：

```text
/path/to/SoCV/gv/build/gv
```

在 gv prompt 依序輸入下列指令；或啟動時：

```text
gv -File run_abs_store.do
```

`.do` 檔內容即 gv 指令本身（不是 shell script）。互動模式下也可用 `DOfile run_abs_store.do`。

---

### Experiment 1：`vending_machine_abs_store.v`

```text
cirr vending_machine_abs_store.v
cirprint -Summary

set system setup
breset 256 20011 50021
bsetorder -file
bconstruct -all

set system vrf
PINITialstate init
PTRansrelation tri tr

PIMAGe -next 1 reach
! 重複數次直到 reach 穩定，或固定 N 次（見 run_abs_store.do）

breport reach

PCHECKProperty -output 16
PCHECKProperty -output 17
PCHECKProperty -output 18
PCHECKProperty -output 19
PCHECKProperty -output 20
PCHECKProperty -output 21
```

對應 monitor：`bad_illegal_service` … `bad_off_not_on`（PO index 16–21）。

---

### Experiment 2：`vending_machine_abs_change.v`

```text
cirr vending_machine_abs_change.v
cirprint -Summary

set system setup
breset 256 20011 50021
bsetorder -file
bconstruct -all

set system vrf
PINITialstate init
PTRansrelation tri tr

PIMAGe -next 1 reach
! 重複數次

breport reach

PCHECKProperty -output 16
PCHECKProperty -output 17
PCHECKProperty -output 18
PCHECKProperty -output 19
! 不證 output 20（bad_fail_gives_item，success 已抽象）
PCHECKProperty -output 21
```

---

### 常用 gv 指令說明

| 指令 | 作用 |
|------|------|
| `cirr <file.v>` | 讀 Verilog |
| `cirprint -Summary` | PI / PO / LATCH / AIG 統計 |
| `set system setup` | 切到 BDD 建構環境 |
| `breset S H C` | 配置 BDD（S ≥ numPI + 2×numLatch） |
| `bsetorder -file` | 依檔案順序設變數順序 |
| `bconstruct -all` | 建所有 gate 的 BDD |
| `set system vrf` | 切到驗證環境 |
| `PINITialstate` | 初始狀態 BDD（全 latch = 0） |
| `PTRansrelation` | 轉移關係 BDD |
| `PIMAGe -next k reach` | 可達狀態映像（重複 k 步或多次呼叫） |
| `breport reach` | 印 reach BDD 節點數 |
| `PCHECKProperty -output i` | 證明 `AG(~PO_i)`（bad monitor） |

結果看 gv 輸出：`[PCHECKProperty] PASS` 或 `FAIL` 與 `witness cube`。

---

## Experiment 1：Stored Coin Register Abstraction

- Concrete：\(store' = \delta(store, coinIn, use, state)\)
- Abstract：`next_store*` ← `free_next_store*`（PI），故 \(store'\) 每 cycle 可任意（3-bit × 4 面額）
- **Over-approx**：含所有 concrete 庫存軌跡，並允許額外 inventory
- **保留**：FSM、找零邏輯、`success` 仍具體

## Experiment 2：Change Calculation Logic Abstraction

- Abstract：`success` ← `free_success`；`use*` ← `free_use*`；無找零 for-loop
- **Over-approx**：任意 success / 找零組合
- **勿證** `bad_fail_gives_item`（output 20）

## Soundness（safety）

- 抽象 **PASS** ⇒ 具體 **PASS**
- 抽象 **FAIL** ⇒ 可能 spurious

## gv 初始狀態

`PINITialstate` 令所有 latch = 0，與 Verilog `reset` 後狀態不同；報告需註明。

---

## 實驗結果（自 gv 輸出填入）

| 性質 | Abs1 | Abs2 |
|------|------|------|
| bad_illegal_service (16) | | |
| bad_item_not_off (17) | | |
| bad_on_req_not_busy (18) | | |
| bad_busy_not_off (19) | | |
| bad_fail_gives_item (20) | | SKIP |
| bad_off_not_on (21) | | |

| 版本 | PI | LATCH | AIG | breport reach |
|------|-----|-------|-----|----------------|
| abs_store | | | | |
| abs_change | | | | |

---

## 檔案

| 檔案 | 說明 |
|------|------|
| `vending_machine_abs_store.v` | Exp. 1 電路 |
| `vending_machine_abs_change.v` | Exp. 2 電路 |
| `vending_machine.v` | Concrete（可選） |
| `run_abs_store.do` | Exp. 1 gv 指令腳本 |
| `run_abs_change.do` | Exp. 2 gv 指令腳本 |
| `run_concrete.do` | Concrete gv 指令腳本 |
