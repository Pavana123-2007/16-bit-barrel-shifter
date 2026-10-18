# 16-bit Barrel Shifter

Design and implementation of a 16-bit barrel shifter in Verilog.
Developed by a 4-person team using a sequential relay workflow.

## Project summary

A barrel shifter shifts or rotates a data word by any amount in a single step.
This design is purely combinational (no clock, no FSM). It uses four stages of
sixteen 2:1 multiplexers that shift by 1, 2, 4 and 8, controlled directly by the
four bits of SHAMT, so any shift from 0 to 15 is the binary sum of the stages
(for example 13 = 8 + 4 + 1). A 2-bit MODE input selects the operation.

|Port|Width|Direction|Meaning|
|-|-|-|-|
|DIN|16|input|Data to be shifted|
|SHAMT|4|input|Shift amount, 0 to 15|
|MODE|2|input|Operation select|
|DOUT|16|output|Shifted or rotated result|

|MODE|Operation|Behaviour|
|-|-|-|
|00|SLL, logical left shift|zeros enter from the right|
|01|SRL, logical right shift|zeros enter from the left|
|10|SRA, arithmetic right shift|sign bit DIN\[15] is replicated on the left|
|11|ROL, rotate left|bits leaving on the left re-enter on the right|

Result: all 4,194,304 combinations (65,536 inputs x 16 shift amounts x 4 modes)
give the correct output, 0 failed.

## Team and roles

|Person|Name|Role|Checkpoint tag|
|-|-|-|-|
|P1|Pavana G|Core architect|v0.1-core|
|P2|Priyal Singh|Functionality / control|v0.2-complete|
|P3|Rakshita Kamarthi|Verification + hardware analysis|v0.3-verified|
|P4|Prarthana N|Documentation, literature, integration|v1.0-final|

## Tools

* Icarus Verilog 12.0 (iverilog, vvp)
* GTKWave (waveform viewer)
* GNU Make (optional, see the plain commands below)
* Git / GitHub
* Code style: plain Verilog-2001 (no SystemVerilog)

## Install notes (Windows)

1. Icarus Verilog + GTKWave: download the Icarus Verilog 12 installer from
bleyer.org/icarus. During install tick "Add executable folder(s) to the
user PATH" and "Install GTKWave".
Note: Icarus Verilog 0.9.7 crashes silently on Windows 11 and produces no
output file. Use version 12.
2. GNU Make (optional): run `winget install GnuWin32.Make`, then add
`C:\\Program Files (x86)\\GnuWin32\\bin` to the user PATH.
Without make, use the plain iverilog commands in "How to build and run".
3. Open a new Command Prompt and check:

   * `iverilog -V` shows version 12.0
   * `make --version` shows GNU Make (if installed)
   * `git --version` shows a version

## Folder map

|Folder / file|Contents|
|-|-|
|src/|Verilog design: shift\_stage.v, barrel\_core.v (basic core); shift\_stage\_mode.v, barrel\_shifter16.v (final design)|
|tb/|Testbenches: tb\_core.v, tb\_barrel\_shifter.v, tb\_exhaustive.v, tb\_waveform.v|
|docs/|Problem statement, architecture, verification results, literature survey, diagrams|
|simulation/|Logs (simulation/logs) and waveforms (simulation/waveforms)|
|report/|final\_report.docx|
|Makefile|Build and test targets|
|HANDOFF.md|Handoff notes between team members, including the independent validation record|

The final design is `barrel\_shifter16` (top level), built from `shift\_stage\_mode`.
`shift\_stage.v` and `barrel\_core.v` are the basic left-shift core. They are kept
unchanged as the regression base and are tested by `make core`.

## How to build and run

Run these from the repository root folder.

|Command|What it does|
|-|-|
|`make core`|Basic core testbench, 128 tests|
|`make sim`|Self-checking testbench for the complete shifter, 972 tests|
|`make exhaustive`|Exhaustive testbench, 4,194,304 tests (about 2 minutes)|
|`make test`|Runs core, sim and exhaustive in order|
|`make bugtest`|Bug-injection check: this run must report failures|
|`make wave`|Directed run that writes simulation/waveforms/barrel.vcd|
|`make clean`|Deletes compiled .out files and .vcd dumps in the root folder|

Without make, the same runs:

&#x20;   iverilog -Wall -o core\_sim.out src/shift\_stage.v src/barrel\_core.v tb/tb\_core.v
    vvp core\_sim.out

    iverilog -Wall -o sim\_bs.out src/shift\_stage\_mode.v src/barrel\_shifter16.v tb/tb\_barrel\_shifter.v
    vvp sim\_bs.out

    iverilog -o exh.out src/shift\_stage\_mode.v src/barrel\_shifter16.v tb/tb\_exhaustive.v
    vvp exh.out


Note: `make clean` uses the Windows `del` command on Windows and `rm -f` elsewhere.

## Expected output

`make core` ends with:

&#x20;   Total tests : 128
    Passed      : 128
    Failed      : 0
    RESULT: ALL TESTS PASSED


`make sim` ends with:

&#x20;   Total tests : 972
    Passed      : 972
    Failed      : 0
    RESULT: ALL TESTS PASSED


`make exhaustive` ends with:

&#x20;   Total tests : 4194304
    Passed      : 4194304
    Failed      : 0
      failures by mode: SLL=0 SRL=0 SRA=0 ROL=0
    RESULT: ALL TESTS PASSED


`make bugtest` flips one output bit for SRA with SHAMT = 5, so it must report
65,536 failures, all in SRA (RESULT: SOME TESTS FAILED). This proves the
exhaustive testbench can detect faults.

## Waveform

Run `make wave`, then open `simulation/waveforms/barrel.vcd` in GTKWave.
A screenshot is saved as `simulation/waveforms/wave\_all\_modes.png`.

## Synthesis (Yosys)

RTL schematic: `docs/diagrams/rtl\_top.png`. Cell counts from Yosys 0.33
(`synth -flatten`, software only), generated on a separate Linux machine:

|Design|MUX cells|Other gates|Total|
|-|-|-|-|
|Basic core (left shift only)|49|17|66|
|barrel\_shifter16 (4 operations)|128|21|149|

Cell counts depend on the tool version and settings.

## Documentation

* `docs/problem\_statement.md`, `docs/architecture.md`
* `docs/verification\_results.md`: test strategy, exhaustive results, bug injection, resource counts
* `docs/literature\_survey.md`: literature survey with four references
* `docs/diagrams/`: architecture and circuit diagrams, RTL schematic
* `report/final\_report.docx`: final project report

## Release tags

|Tag|Content|
|-|-|
|v0.1-core|Four-stage logical left shift core and its testbench|
|v0.2-complete|Four operations (SLL, SRL, SRA, ROL) and self-checking testbench|
|v0.3-verified|Exhaustive verification, waveforms, RTL schematic and cell counts|
|v1.0-final|Final report, literature survey, clean repository|

## Status

* \[x] v0.1-core
* \[x] v0.2-complete
* \[x] v0.3-verified
* \[x] v1.0-final

