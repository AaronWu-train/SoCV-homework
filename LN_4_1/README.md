# LN_4_1 — 4-bit adder & 4×4 multiplier

Structural Verilog: `full_adder` → fixed-width ripple chains in `adder_4`, `adder_6`, `adder_7`, `adder_8` → `mult_4`.

## Files

| File | Description |
|------|-------------|
| `full_adder.v` | 1-bit full adder |
| `adder_4.v` | 4-bit adder (`cin` / `cout`), explicit `full_adder` chain |
| `adder_wide.v` | `adder_6`, `adder_7`, `adder_8` for multiplier partial-product sums |
| `mult_4.v` | 4×4 unsigned multiplier, 8-bit product `p` |
| `tb_ln41.v` | Self-checking testbench for `adder_4` and `mult_4` |

Compile **in dependency order** (or list in this order so symbols resolve).

## Compile & simulate (Icarus Verilog)

Install: [Icarus Verilog](http://iverilog.icarus.com/) (`iverilog`, `vvp` on `PATH`).

From this directory:

```bash
iverilog -Wall -g2012 -o sim.vvp \
  full_adder.v \
  adder_4.v \
  adder_wide.v \
  mult_4.v \
  tb_ln41.v

vvp sim.vvp
```

You should see `PASS tb_ln41 (adder exhaustive + mult exhaustive)`. To simulate only RTL without the testbench, omit `tb_ln41.v` and supply your own top module.

## Other tools

For **Verilator**, **Vivado**, or **Quartus**, add all `.v` files to the project and set the testbench or top module as required by that tool; file order is usually not significant when using a project file.
