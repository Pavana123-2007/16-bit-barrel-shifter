# HANDOFF.md

One section per handoff. Each person fills in their own section when they
tag their checkpoint. Do not edit another person's section.

## Handoff 1: P1 to P2 (v0.1-core)

| Field | Content |
|-------|---------|
| From / To | Pavana G (P1) to Priyal Singh (P2), 2026-10-09 |
| Tag | v0.1-core |
| How to build and run | `make core` (or `make test`). Without make: `iverilog -Wall -o core_sim.out src/shift_stage.v src/barrel_core.v tb/tb_core.v` then `vvp core_sim.out` |
| Expected output | One PASS line per case, then `Total tests : 128`, `Passed : 128`, `Failed : 0`, `RESULT: ALL TESTS PASSED` |
| What is done | 4-stage logarithmic MUX core (shifts 1, 2, 4, 8), logical left shift with zero fill, for all shift amounts 0-15. Basic testbench tb_core.v: shifts 0/1/2/4/8/15, patterns 0x0001/0x8000/0xA5A5/0x5555/0x1234, all-zero and all-one inputs, full 16-amount sweep for 7 patterns (128 cases, all PASS). Compiles with no errors or warnings. Docs: problem statement, architecture, MUX explanation, shift-by-13 example, 4-stage diagram, README. |
| Known issues / limitations | Core supports SLL only (no MODE yet). Requires Icarus Verilog 12 (0.9.7 crashes silently on Windows 11 and writes no output file). `make clean` uses the Windows `del` command. |
| Interface contract | `shift_stage`: parameter SHIFT; ports in[15:0] (input), sel (input), out[15:0] (output). `barrel_core`: ports DIN[15:0] (input), SHAMT[3:0] (input), DOUT[15:0] (output). SHAMT[0] -> x1, SHAMT[1] -> x2, SHAMT[2] -> x4, SHAMT[3] -> x8. Frozen; see docs/architecture.md. |
| What the receiver must do next | 1. Clone v0.1-core, run `make core`, confirm 128/128 PASS, record the result here (P2.0 gate). 2. Create branch p2-functionality. 3. Build src/barrel_shifter16.v with MODE (SLL, SRL, SRA, ROL) reusing the staged core. 4. Write tb/tb_barrel_shifter.v (self-checking). 5. Keep `make core` passing. |

## Handoff 2: P2 to P3 (v0.2-complete)

| Field | Content |
|-------|---------|
| From / To | Priyal Singh (P2) to P3 (P3), 2026-10-11 |
| Tag | v0.2-complete |
| P2.0 gate result | Cloned v0.1-core (7d81873), Icarus Verilog 13.0 on macOS: `make core` printed Total 128, Passed 128, Failed 0, ALL TESTS PASSED. Gate passed before any change. |
| How to build and run | `make core` (P1, 128 tests), `make sim` (P2, 972 tests), `make test` (both). Without make: `iverilog -Wall -o sim_bs.out src/shift_stage_mode.v src/barrel_shifter16.v tb/tb_barrel_shifter.v` then `vvp sim_bs.out` |
| Expected output | `make sim` ends with `Total tests : 972`, `Passed : 972`, `Failed : 0`, `RESULT: ALL TESTS PASSED`. `make core` ends with 128 / 128 / 0. |
| What is done | Top module `barrel_shifter16` with MODE: 00 SLL, 01 SRL, 10 SRA, 11 ROL, all 16 shift amounts. New mode-aware stage `shift_stage_mode` (16 x 2:1 MUX per stage with direction / rotate / fill), same 4-stage structure, SHAMT[0..3] -> x1, x2, x4, x8. Self-checking testbench with reference model: 12 hand-computed values, 704 directed cases (11 edge patterns x 4 modes x 16 shifts), 256 random. Edge cases: SHAMT 0 and 15, 0x0000, 0xFFFF, 0x8000, 0x7FFF, 0xAAAA, 0x5555, negative SRA. Docs: MODE table, control decode, stage rule, Option B justification, worked examples (docs/architecture.md section 6), circuit diagram docs/diagrams/complete_circuit.svg, README. Makefile: added `sim`, `test` = core + sim, portable `clean`. Compiles with no warnings. |
| Known issues / limitations | P1's `shift_stage.v` and `barrel_core.v` are kept unchanged as the regression base, but `barrel_shifter16` does NOT instantiate them; it uses `shift_stage_mode`. So for synthesis use `src/shift_stage_mode.v src/barrel_shifter16.v` (top = barrel_shifter16). Random tests use `$random` with the default seed (reproducible). The exhaustive 4,194,304-case run is P3's job. Circuit diagram is a hand-written SVG; P4 may redraw it in the final style. |
| Interface contract | `barrel_shifter16`: DIN[15:0] in, SHAMT[3:0] in, MODE[1:0] in, DOUT[15:0] out. `shift_stage_mode`: parameter SHIFT; in[15:0], sel, right, rot, fill (inputs), out[15:0] output. MODE: 00 SLL, 01 SRL, 10 SRA, 11 ROL. Frozen; see docs/architecture.md section 6. P1's interfaces unchanged. |
| What the receiver must do next | 1. Clone v0.2-complete, run `make test`, confirm P1 128/128 and P2 972/972 PASS (P3.0 gate). 2. Write tb/tb_exhaustive.v (4,194,304 cases, independent reference model), add `make exhaustive`, save log to simulation/logs/exhaustive.log. 3. Mutation check (break the DUT, confirm failures, restore). 4. Waveforms, Yosys schematic and cell counts, architecture comparison. 5. Tag v0.3-verified. |

## Handoff 3: P3 to P4 (v0.3-verified)

(To be filled in by P3.)

## Handoff 4: P4 final (v1.0-final)

(To be filled in by P4.)