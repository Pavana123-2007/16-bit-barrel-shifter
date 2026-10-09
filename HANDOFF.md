# HANDOFF.md

One section per handoff. Each person fills in their own section when they
tag their checkpoint. Do not edit another person's section.

## Handoff 1: P1 to P2 (v0.1-core)

| Field | Content |
|-------|---------|
| From / To | Pavana G (P1) to (P2 name) (P2), 2026-10-09 |
| Tag | v0.1-core |
| How to build and run | `make core` (or `make test`). Without make: `iverilog -Wall -o core_sim.out src/shift_stage.v src/barrel_core.v tb/tb_core.v` then `vvp core_sim.out` |
| Expected output | One PASS line per case, then `Total tests : 128`, `Passed : 128`, `Failed : 0`, `RESULT: ALL TESTS PASSED` |
| What is done | 4-stage logarithmic MUX core (shifts 1, 2, 4, 8), logical left shift with zero fill, for all shift amounts 0-15. Basic testbench tb_core.v: shifts 0/1/2/4/8/15, patterns 0x0001/0x8000/0xA5A5/0x5555/0x1234, all-zero and all-one inputs, full 16-amount sweep for 7 patterns (128 cases, all PASS). Compiles with no errors or warnings. Docs: problem statement, architecture, MUX explanation, shift-by-13 example, 4-stage diagram, README. |
| Known issues / limitations | Core supports SLL only (no MODE yet). Requires Icarus Verilog 12 (0.9.7 crashes silently on Windows 11 and writes no output file). `make clean` uses the Windows `del` command. |
| Interface contract | `shift_stage`: parameter SHIFT; ports in[15:0] (input), sel (input), out[15:0] (output). `barrel_core`: ports DIN[15:0] (input), SHAMT[3:0] (input), DOUT[15:0] (output). SHAMT[0] -> x1, SHAMT[1] -> x2, SHAMT[2] -> x4, SHAMT[3] -> x8. Frozen; see docs/architecture.md. |
| What the receiver must do next | 1. Clone v0.1-core, run `make core`, confirm 128/128 PASS, record the result here (P2.0 gate). 2. Create branch p2-functionality. 3. Build src/barrel_shifter16.v with MODE (SLL, SRL, SRA, ROL) reusing the staged core. 4. Write tb/tb_barrel_shifter.v (self-checking). 5. Keep `make core` passing. |

## Handoff 2: P2 to P3 (v0.2-complete)

(To be filled in by P2.)

## Handoff 3: P3 to P4 (v0.3-verified)

(To be filled in by P3.)

## Handoff 4: P4 final (v1.0-final)

(To be filled in by P4.)