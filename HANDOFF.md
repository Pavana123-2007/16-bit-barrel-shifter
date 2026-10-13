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

| Field | Content |
|-------|---------|
| From / To | Rakshita Kamarthi (P3) to P4, 2026-10-12 |
| Tag | v0.3-verified |
| P3.0 gate result | Cloned v0.2-complete (055c508), Icarus Verilog 12.0 on Windows: P1 core test 128/128 PASS and P2 test 972/972 PASS before any change. Gate passed. |
| How to build and run | Exhaustive test: `iverilog -o exh.out src\shift_stage_mode.v src\barrel_shifter16.v tb\tb_exhaustive.v` then `vvp exh.out`. Bug-injection test: add `-DINJECT_BUG` to the iverilog command (it must report failures). Waveform run: `iverilog -o wave.out src\shift_stage_mode.v src\barrel_shifter16.v tb\tb_waveform.v` then `vvp wave.out`, open simulation\waveforms\barrel.vcd in GTKWave. |
| Expected output | The exhaustive run ends with `Total tests : 4194304`, `Passed : 4194304`, `Failed : 0`, `RESULT: ALL TESTS PASSED` (about 2 minutes). The bug-injection run ends with `Failed : 65536` (all in SRA) and `RESULT: SOME TESTS FAILED`, which is expected. |
| What is done | tb/tb_exhaustive.v: every input (65,536) x every shift amount (16) x every mode (4) = 4,194,304 cases, 0 failed. The reference model is independent: it shifts one bit at a time, SHAMT times, without using the shift operators. The bug-injection check proves the testbench detects faults (65,536 failures, all SRA). tb/tb_waveform.v and simulation/waveforms/wave_all_modes.png: directed run for all 4 modes and edge cases, values match the hand-computed table. docs/verification_results.md: test strategy, results, bug check, waveforms, RTL and resource numbers, staged vs large-MUX comparison. docs/diagrams/rtl_top.png: Yosys RTL schematic. Logs are in simulation/logs/. No file in src/ was changed. |
| Known issues / limitations | The design under test is barrel_shifter16 + shift_stage_mode (P1's barrel_core is not instantiated by the top module). The Yosys schematic and cell counts (P1 core 49 MUX + 17 gates; full design 128 MUX + 21 gates = 149 cells) were generated with Yosys 0.33 on a separate Linux machine, not on the Windows machine. Cell counts depend on tool version. The VCD file is not committed (.gitignore); regenerate it with the waveform run. The exhaustive run takes about 2 minutes. The Makefile has no exhaustive target (GNU Make was not available on the P3 machine). |
| Interface contract | Unchanged. barrel_shifter16: DIN[15:0], SHAMT[3:0], MODE[1:0] in, DOUT[15:0] out. MODE: 00 SLL, 01 SRL, 10 SRA, 11 ROL. |
| What the receiver must do next | 1. Clone v0.3-verified and re-run the three testbenches, confirming P1 128/128, P2 972/972 and exhaustive 4,194,304 / 0 failed (P4 gate). 2. Collect one literature source from each of the 4 members and write docs/literature_survey.md (1-2 pages, verify every reference exists). 3. Assemble report/final_report.docx (11 sections) using docs/verification_results.md, the logs, wave_all_modes.png and rtl_top.png. 4. Finalise the README, clean the repo, tag v1.0-final. |

## Handoff 4: P4 final (v1.0-final)

(To be filled in by P4.)

## Handoff 4 - P4 independent validation (fresh clone of v0.3-verified)

| Field | Content |
|---|---|
| Validated by | Prarthana N, 13-10-2026 |
| Tag validated | v0.3-verified (commit 8df04e7) |
| Environment | Windows 11 Home 25H2 (build 26200.9457), cmd, Icarus Verilog 12.0 (devel) (s20150603-1539-g2693dd32b); no make, commands run manually |
| tb_core (P1) | Total 128, Passed 128, Failed 0 - ALL TESTS PASSED |
| tb_barrel_shifter (P2) | Total 972, Passed 972, Failed 0 - ALL TESTS PASSED |
| tb_exhaustive (P3) | Total 4194304, Passed 4194304, Failed 0 (SLL=0 SRL=0 SRA=0 ROL=0) - ALL TESTS PASSED |
| Notes | barrel_shifter16 uses shift_stage_mode.v; shift_stage.v and barrel_core.v are the P1 regression base only. Makefile has no exhaustive target at this tag; exhaustive test run manually from HANDOFF.md commands. Yosys cell counts (128 MUX + 21 gates) were produced by P3 on a separate Linux machine with Yosys 0.33, not on this machine. |
| Next (P4) | Literature survey, final report, README/Makefile cleanup, tag v1.0-final |
