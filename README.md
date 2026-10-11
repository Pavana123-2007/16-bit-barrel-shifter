# 16-bit Barrel Shifter

Design and implementation of a 16-bit barrel shifter in Verilog.
Developed by a 4-person team using a sequential relay workflow.

## Team and roles

| Person | Role | Checkpoint tag |
|--------|------|----------------|
| P1 - Pavana G | Core architect | v0.1-core |
| P2 | Functionality / control | v0.2-complete |
| P3 | Verification + hardware analysis | v0.3-verified |
| P4 | Documentation, literature, integration | v1.0-final |

## Tools

- Icarus Verilog 12.0 (iverilog, vvp)
- GTKWave (waveform viewer)
- GNU Make
- Git / GitHub
- Code style: plain Verilog-2001 (no SystemVerilog)

## Install notes (Windows)

1. Icarus Verilog + GTKWave: download the Icarus Verilog 12 installer from
   bleyer.org/icarus. During install tick "Add executable folder(s) to the
   user PATH" and "Install GTKWave".
   Note: Icarus Verilog 0.9.7 crashes silently on Windows 11 and produces no
   output file. Use version 12.
2. GNU Make: run `winget install GnuWin32.Make`, then add
   `C:\Program Files (x86)\GnuWin32\bin` to the user PATH.
3. Open a new Command Prompt and check:
   - `iverilog -V` shows version 12.0
   - `make --version` shows GNU Make
   - `git --version` shows a version

## Folder map

| Folder / file | Contents |
|---------------|----------|
| src/ | Verilog design files |
| tb/ | Testbenches |
| docs/ | Problem statement, architecture, literature survey, diagrams |
| simulation/ | Logs and waveforms |
| report/ | Final report |
| Makefile | Build and test targets |
| HANDOFF.md | Handoff notes between team members |

## How to build and run

Run these from the repository root folder.

| Command | What it does |
|---------|--------------|
| `make core` | Compiles src/shift_stage.v, src/barrel_core.v and tb/tb_core.v, then runs the simulation |
| `make test` | Runs all testbenches in order (currently only core) |
| `make clean` | Deletes compiled .out files and .vcd dumps |

Without make, the same as `make core`:

    iverilog -Wall -o core_sim.out src/shift_stage.v src/barrel_core.v tb/tb_core.v
    vvp core_sim.out

Note: `make clean` uses the Windows `del` command.

## Expected output (make core)

One PASS line per test case, then:

    Total tests : 128
    Passed      : 128
    Failed      : 0
    RESULT: ALL TESTS PASSED

## Status

- [x] v0.1-core (P1)
- [ ] v0.2-complete (P2)
- [ ] v0.3-verified (P3)
- [ ] v1.0-final (P4)
## Complete shifter (P2, v0.2-complete)

`barrel_shifter16` supports four operations selected by MODE:

| MODE | Operation |
|------|-----------|
| 00 | SLL, logical left shift |
| 01 | SRL, logical right shift |
| 10 | SRA, arithmetic right shift |
| 11 | ROL, rotate left |

Ports: `DIN[15:0]`, `SHAMT[3:0]`, `MODE[1:0]`, `DOUT[15:0]`.

Run:

    make core    # P1 core testbench (128 tests)
    make sim     # P2 self-checking testbench (972 tests)
    make test    # both, in order

Expected output of `make sim` ends with:

    Total tests : 972
    Passed      : 972
    Failed      : 0
    RESULT: ALL TESTS PASSED

Source files added by P2: `src/shift_stage_mode.v`, `src/barrel_shifter16.v`,
`tb/tb_barrel_shifter.v`. P1's files are unchanged.
