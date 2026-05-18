## 實驗目標

- 針對 vending machine design 做 **over-approximate** circuit abstraction，並觀察 BDD 驗證流程（`bconstruct` → `PTRansrelation`）是否可行。
- 觀察重點：
  1. `bconstruct -all` 是否可完成。
  2. `PTRansrelation tri tr` 是否可在合理時間內完成（本次以 **60s** 為門檻）。
  3. 若後續做 `PIMAGe` / `PCHECKProperty`，proof 對 control property 是否仍 sound。
  4. abstract FAIL 是否可能為 spurious counter-example。

- 背景：依 [Week 7 (04/08)](https://www.notion.so/Week-7-04-08-33c43f8c848d80388282cd1ad58616ac?pvs=21) LN-5-2；**concrete design**（`vending_machine.v`）在目前 GV 設定下規模過大（AIG ≈ 11k），無法作為本次 BDD 流程的起點。

---

## 最終採用的兩個抽象

對應檔案：

| 實驗                 | Verilog                              | gv script                 |
| -------------------- | ------------------------------------ | ------------------------- |
| Exp.1 Store + Change | `vending_machine_abs_store_change.v` | `run_abs_store_change.do` |
| Exp.2 FSM only       | `vending_machine_abs_fsm_only.v`     | `run_abs_fsm_only.do`     |

測試指令：

```bash
gtimeout 60s gv -F run_abs_store_change.do
gtimeout 60s gv -F run_abs_fsm_only.do
```

---

### Experiment 1：Store + Change Abstraction（精簡版）

**設計意圖（與最初規劃的差異）**

- 原計畫：保留完整 FSM + `req_*` / `disp_*` / `store_*` latch，並以 `free_next_store*`、`free_use*`、`free_success` 抽象庫存與找零。
- **實際採用（為了讓 `PTRansrelation` 在 60s 內完成）**：在保留 FSM 與 control monitor 的前提下，進一步刪減 latch / PI：
  - **移除** `store*` 與 `free_next_store*`（庫存狀態不再建模，每步視為非確定 → 仍為 over-approx）。
  - **移除** `req_in*` latch（不再精確 latch 投入硬幣）。
  - **移除** 逐面額 `disp50/10/5/1`，改為單一 `disp_coin`（成功/失敗時由 `free_give_change` / `free_return_coins` 決定四種面額同時為 0 或 1）。
  - **保留** `state`、`req_item`、`disp_item` + `disp_coin`、五個 `bad_*` monitor（無 `bad_fail_gives_item`）。

**Free inputs（3 個）**

- `free_success`：交易成功與否。
- `free_give_change`：成功時是否輸出找零（四種 coinOut 同時為 `3'd1` 或全 0）。
- `free_return_coins`：失敗時是否退幣（同上編碼）。

**Over-approximate 理由**

- Concrete 的任一筆交易結果（成功/失敗、找零有無、退幣有無）都可由上述 free PI 在該 cycle 選到對應值；抽象版額外允許不對應真實算術的組合。
- 未刪除 concrete 可能出現的 **FSM 軌跡**（ON→BUSY→OFF→ON），故對 control safety 仍可做 sound 推論。

---

### Experiment 2：FSM-Control-Only Abstraction（精簡版）

**保留**

- `state`（2-bit service FSM）。
- FSM transition：
  - `SERVICE_ON` 無 request → 維持 ON
  - `SERVICE_ON` 有 request → `SERVICE_BUSY`
  - `SERVICE_BUSY` → `SERVICE_OFF`
  - `SERVICE_OFF` → `SERVICE_ON`
- 五個 control monitor。

**抽象掉**

- 所有 datapath latch（store、req、disp）。
- 價格、找零、庫存、精確 coin/item 輸出。

**Free inputs（2 個）**

- `free_give_item`：僅在 `SERVICE_OFF` 時，若為 1 則 `itemTypeOut = ITEM_A`（代表「有輸出商品」之任一非 NONE 情況）。
- `free_give_coin`：僅在 `SERVICE_OFF` 時，若為 1 則四種 `coinOut*` 皆為 `3'd1`。

**輸出約束（仍保留的 concrete 結構）**

- `itemTypeOut` / `coinOut*` 在 **非 OFF** state 強制為 NONE / 0（與 concrete 介面語意一致）。

---

## Properties

**適合檢查（sound over-approx）**

- `bad_illegal_service`
- `bad_item_not_off`
- `bad_on_req_not_busy`
- `bad_busy_not_off`
- `bad_off_not_on`

**不適合檢查**

- `bad_fail_gives_item`（兩個最終抽象皆無此 PO；且 `free_success` 已非具體語意）
- 找零正確性、價格、庫存守恆、吞幣與否等 datapath / money 性質

**結果解讀**

- Abstract **PASS** ⇒ Concrete **PASS**（對上述 control safety）。
- Abstract **FAIL** ⇒ 可能是 spurious，不能直接判定 concrete 有 bug。

**PO 編號注意**：最終版 PO 為 **21** 個（無 `bad_fail_gives_item`），`PCHECKProperty -output` 索引與含 22 個 PO 的 `abs_change` 不同；請以 `cirprint -Summary` 或 netlist 順序為準。

---

## 電路規模（`cirprint -Summary`）

| 版本                                  | PI  | PO  | LATCH | AIG   |
| ------------------------------------- | --- | --- | ----- | ----- |
| concrete `vending_machine.v`          | 12  | 22  | 70    | 11372 |
| 中間版 `vending_machine_abs_change.v` | 25  | 22  | 38    | 748   |
| **最終** `abs_store_change`           | 15  | 21  | 7     | 125   |
| **最終** `abs_fsm_only`               | 14  | 21  | 2     | 50    |

---

## 實驗結果與討論

### 1. `bconstruct -all`

- 最終兩版均可快速完成（與 concrete / `abs_change` 相比，AIG 小 1～2 個數量級）。

### 2. `PTRansrelation tri tr`（60s 門檻）

| 版本                                                     | 60s 內 `PTRansrelation` | 備註                                                      |
| -------------------------------------------------------- | ----------------------- | --------------------------------------------------------- |
| `abs_change`（中間版，38 latch + `avail-use`）           | **否**                  | `bconstruct` 可完成，但 TR 建構 >60s（實測 user time 高） |
| 初版 `abs_store_change`（37 PI、38 latch、多組 free PI） | **否**                  | 即使比 `abs_change` AIG 更小，TR 仍 >120s                 |
| **最終** `abs_store_change`                              | **是**（約 0.1s）       | 需 `quit -force`                                          |
| 初版 `abs_fsm_only`（14-bit free OFF 輸出）              | 表面逾時                | 多數情況是 gv 未退出，非 TR 過慢                          |
| **最終** `abs_fsm_only`                                  | **是**（約 0.1s）       | 需 `quit -force`                                          |

### 3. 為何「抽象了還是慢」？後來又如何變快？

**（A）量測陷阱：`gtimeout` 與 gv 互動**

- `gv -F xxx.do` 執行完 dofile 後若沒有 `quit -force`，process 會留在 prompt。
- 此時 `gtimeout 60s` 會等滿 60s 才 kill，**不代表** `PTRansrelation` 算了 60s（`fsm_only` 初版即屬此類）。

**（B）真正的 BDD 瓶頸：TR = ∧ᵢ (NSᵢ ↔ fᵢ(CS, PI))，再對所有 PI 做 exist**

- GV 實作見 `proveBdd.cpp`：`buildPTransRelation` 對 **每個 latch** 建 next-state BDD，再對 **全部 PI** 逐一 `exist`。
- 因此 **LATCH 數** 與 **PI 數** 同時影響 TR 大小；僅砍掉 for-loop、保留 38 個 latch + 20+ free PI（初版 `abs_store_change`）仍不夠。
- 有效做法是：**減 latch**（去掉 store / req_in / 逐面額 disp）並 **壓縮 free PI 位寬**（3-bit×多組 → 1-bit flag）。

**（C）抽象「語意上夠鬆」≠「BDD 夠小」**

- Over-approx 用 non-deterministic PI 表達「任選一個合法後果」；PI 過多會讓 exist 前的 TR 暴脹。
- 實務上要在 soundness 與 BDD 可建性之間折衷：用 **少數 1-bit free flag** 代表一整類 datapath 行為，而非逐信號 unconstrained。

### 4. 本次未完成的部分

- 在 `PTRansrelation` 之後的 **`PIMAGe` / `PCHECKProperty`** 尚未系統跑完並填表。
- `PINITialstate` 令所有 latch = 0，與 Verilog `reset` 後狀態（例如 store=2）不一致；若要做完整 reachability 比對，需在報告中註明或另建 init。

### 5. 結論（修正舊筆記）

- ~~「即使 aggressive abstraction 仍無法在兩分鐘內完成 TR」~~ → **不成立**；在**進一步精簡 latch/PI** 並修正 dofile 退出方式後，**最終兩版可在 60s 內完成 `PTRansrelation`**。
- Concrete 與中間版 `abs_change` 仍不適合作為本次 BDD TR 的目標；**最終 `abs_store_change` / `abs_fsm_only` 才是可繼續往 reachability / property checking 推進的版本**。
- 中間檔案 `vending_machine_abs_change.v`、`vending_machine_abs_store.v` 僅作嘗試紀錄，**不納入最終結論**。

---

## 相關檔案

- Concrete：`vending_machine.v`
- 最終抽象：`vending_machine_abs_store_change.v`、`vending_machine_abs_fsm_only.v`
- gv：`run_abs_store_change.do`、`run_abs_fsm_only.do`
- 中間嘗試（參考用）：`vending_machine_abs_change.v`、`run_abs_change.do`
