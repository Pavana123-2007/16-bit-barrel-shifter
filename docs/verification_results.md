# Verification and hardware analysis (P3)

## 1\. Test strategy

Three levels of testing, each keeping the previous one passing:

|Level|Testbench|Owner|Cases|Method|
|-|-|-|-|-|
|1|tb/tb\_core.v|P1|128|Directed tests of the left-shift core (shifts 0/1/2/4/8/15, patterns, sweep)|
|2|tb/tb\_barrel\_shifter.v|P2|972|Self-checking: hand-computed values, 11 edge patterns x 4 modes x 16 shifts, 256 random; reference model uses Verilog operators|
|3|tb/tb\_exhaustive.v|P3|4,194,304|Every input x every shift amount x every mode|

## 2\. Exhaustive verification

* Space covered: 65,536 inputs x 16 shift amounts x 4 modes = 4,194,304 cases.
* Design under test: `barrel\_shifter16` (with `shift\_stage\_mode`), unchanged from v0.2-complete.
* The reference model is independent of the DUT and of P2's model: it moves the
data ONE bit position at a time, SHAMT times, using concatenation only
(no `<<`, `>>`, `>>>`). SLL: `{r\[14:0],1'b0}`, SRL: `{1'b0,r\[15:1]}`,
SRA: `{r\[15],r\[15:1]}`, ROL: `{r\[14:0],r\[15]}`.
* Result (log: simulation/logs/exhaustive.log):

```
Total tests : 4194304
Passed      : 4194304
Failed      : 0
```

* Simulator: Icarus Verilog 12.0 (devel). Run time: about 1 min 54 s (11:41:44 to 11:43:38).



## 3\. Proof that the testbench can fail (bug injection)

If a testbench never fails, "0 failed" proves nothing. Two checks were made:

1. `iverilog -DINJECT\_BUG` flips the LSB of the output for SRA with SHAMT = 5.
Result: Failed = 65,536 (all in SRA), exactly the 65,536 inputs of that one case.
Log: simulation/logs/exhaustive\_bugtest.log
2. A real design fault, in a temporary copy only: the SRA fill bit was forced
to 0 instead of DIN\[15]. Result: Failed = 491,520 (all in SRA mode).
This equals 15 shift amounts x 32,768 negative inputs, as expected.
The repository code was not changed.

## 4\. Waveforms

Produced with tb/tb\_waveform.v and GTKWave (simulation/waveforms/barrel.vcd).
Screenshots: simulation/waveforms/wave\_all\_modes.png. Hand-checked values:

|DIN|SHAMT|SLL|SRL|SRA|ROL|
|-|-|-|-|-|-|
|0x8001|1|0x0002|0x4000|0xC000|0x0003|
|0xF0F0|4|0x0F00|0x0F0F|0xFF0F|0x0F0F|

Edge cases: 0x8000 SRA 15 = 0xFFFF; 0x8000 SRL 15 = 0x0001; 0xFFFF with SHAMT 0 = 0xFFFF;
0x1234 SLL 13 = 0x8000 (13 = 8 + 4 + 1, stages 1, 3 and 4 active).

## 5\. RTL schematic and resource count

Tool: Yosys 0.33 (software only, no FPGA or board). Files synthesised:
src/shift\_stage\_mode.v and src/barrel\_shifter16.v, top = barrel\_shifter16.

* Schematic: docs/diagrams/rtl\_top.png shows the control decode (right, rot, fill)
feeding four `shift\_stage\_mode` instances (x1, x2, x4, x8) in series.
* Generic gate count after `synth -flatten`:

|Design|$*MUX*|Other gates|Total cells|
|-|-|-|-|
|P1 core (left shift only)|49|17|66|
|barrel\_shifter16 (4 operations)|128|21|149|

Notes: the P1 core is 4 stages x 16 = 64 two-input selections; Yosys turns the
15 zero-fill ones into AND-NOT gates, which is why it reports 49 MUX + 15 ANDNOT.
The full design needs two selections per bit per stage (enable, then direction):
4 x 16 x 2 = 128 MUXes, plus about 21 gates for the control decode and fill/rotate
logic. Cell counts depend on tool version and settings, so quote the version.

## 6\. Architecture comparison: staged vs large MUX

||Staged logarithmic (ours)|Large-MUX design|
|-|-|-|
|Structure|4 stages, one 2:1 MUX per bit per stage|one 16:1 MUX per output bit|
|MUXes, left shift only|4 x 16 = 64|16 x 15 = 240 (2:1 equivalents)|
|MUX levels|log2(16) = 4|4 levels of 2:1, with 16 decoded select lines|
|Control|4 SHAMT bits used directly|decoder needed|
|Scalability (n bits)|n log2(n) MUXes|about n x (n-1) MUXes|

Why the staged architecture? It needs only log2(16) = 4 levels, and any shift
amount is built from the binary representation of SHAMT (e.g. 13 = 8 + 4 + 1),
using far fewer MUXes and a simple 4-bit control.

## 7\. Conclusion of verification

All 4,194,304 input/shift/mode combinations produce the correct result, the
testbench is shown to detect injected and real faults, and the synthesised
structure matches the intended four-stage MUX design.

