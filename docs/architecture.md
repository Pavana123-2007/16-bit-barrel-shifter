# Architecture (P1 core, frozen at v0.1-core)

## 1. Overview

A 16-bit barrel shifter is a purely combinational circuit (no clock, no FSM)
that shifts a 16-bit word by any amount from 0 to 15 in a single step.
The core built by P1 performs a LOGICAL LEFT SHIFT with ZERO FILL.
P2 extends it to SLL, SRL, SRA and ROL using a MODE input.

## 2. Why 4 stages

16 = 2^4, so log2(16) = 4 stages are enough. Any shift amount 0-15 is the
binary sum of 1, 2, 4 and 8. Each stage either shifts by its own amount or
passes the data through unchanged, controlled by one bit of SHAMT.

| Stage | Shift if enabled | Select bit |
|-------|------------------|------------|
| 1 | 1 | SHAMT[0] |
| 2 | 2 | SHAMT[1] |
| 3 | 4 | SHAMT[2] |
| 4 | 8 | SHAMT[3] |

Example: shift by 13 = 1101 in binary = 8 + 4 + 1, so stages 1, 3 and 4 are
enabled and stage 2 passes the data through.

## 3. Structure

One stage = 16 two-to-one MUXes (one per bit).
Four stages = 4 x 16 = 64 two-to-one MUXes for the core.

    shamt[0]   shamt[1]   shamt[2]   shamt[3]
       |          |          |          |
DIN -> [Stage 1] -> [Stage 2] -> [Stage 3] -> [Stage 4] -> DOUT
          (x1)        (x2)        (x4)        (x8)

## 4. Frozen interface (do not change without team agreement)

### Module shift_stage (file src/shift_stage.v)

| Item | Name | Width | Direction | Meaning |
|------|------|-------|-----------|---------|
| parameter | SHIFT | - | - | Shift amount of this stage (1, 2, 4 or 8) |
| port | in | 16 | input | Data coming into the stage |
| port | sel | 1 | input | 0 = pass through, 1 = shift left by SHIFT |
| port | out | 16 | output | Data leaving the stage |

Rule per output bit i:
- sel = 0: out[i] = in[i]
- sel = 1: out[i] = in[i - SHIFT] when i >= SHIFT, otherwise 0

### Module barrel_core (file src/barrel_core.v)

| Item | Name | Width | Direction | Meaning |
|------|------|-------|-----------|---------|
| port | DIN | 16 | input | Data to be shifted |
| port | SHAMT | 4 | input | Shift amount 0-15 |
| port | DOUT | 16 | output | DIN << SHAMT, zero filled |

Internal buses: s1, s2, s3 (16 bits each) join the four stages.

## 5. Conventions

- Bit 0 is the least significant bit (LSB). Bit 15 is the most significant (MSB).
- Verilog-2001 only (no SystemVerilog), so it compiles on Icarus Verilog 0.9.7.
- Stages are written as visible MUXes (conditional expressions), NOT with the
  behavioural << operator. The << operator is used only inside testbenches
  as the reference model.
- Port names and widths above are frozen from tag v0.1-core onward.

## 6. Notes for P2 (to be completed by P2)

### 6.1 Complete design (P2, tag v0.2-complete)

The complete shifter is `barrel_shifter16` (src/barrel_shifter16.v). It keeps the
same 4-stage logarithmic structure as P1's core (SHAMT[0] -> x1, SHAMT[1] -> x2,
SHAMT[2] -> x4, SHAMT[3] -> x8) but each stage is now the mode-aware
`shift_stage_mode` (src/shift_stage_mode.v). The design is purely combinational,
so no FSM is needed. P1's files (shift_stage.v, barrel_core.v, tb_core.v) are
unchanged and `make core` still passes.

### 6.2 MODE table

| MODE | Operation | Abbrev. | Direction | Fill / behaviour |
|------|-----------|---------|-----------|------------------|
| 00 | Logical Left Shift | SLL | left | zeros enter from the right |
| 01 | Logical Right Shift | SRL | right | zeros enter from the left |
| 10 | Arithmetic Right Shift | SRA | right | sign bit DIN[15] enters from the left |
| 11 | Rotate Left | ROL | left | bits leaving the left re-enter on the right |

### 6.3 Control decode (MODE -> stage controls)

| MODE | right | rot | fill |
|------|-------|-----|------|
| 00 SLL | 0 | 0 | 0 |
| 01 SRL | 1 | 0 | 0 |
| 10 SRA | 1 | 0 | DIN[15] |
| 11 ROL | 0 | 1 | 0 (unused) |

Boolean equations (M1 = MODE[1], M0 = MODE[0]):

- right = M1 XOR M0
- rot   = M1 AND M0
- fill  = M1 AND (NOT M0) AND DIN[15]

These three signals are shared by all four stages. Each stage's own enable is
still its SHAMT bit.

### 6.4 Rule of one stage (shift_stage_mode, shift amount S)

For output bit i, when the stage enable sel = 1:

| Case | Output bit |
|------|------------|
| left, i >= S | in[i - S] |
| left, i < S, rot = 0 (SLL) | 0 |
| left, i < S, rot = 1 (ROL) | in[i - S + 16] (wrapped bit) |
| right, i + S <= 15 | in[i + S] |
| right, i + S > 15 | fill (0 for SRL, DIN[15] for SRA) |

When sel = 0, out[i] = in[i] (pass through).

### 6.5 Design choice: direction-aware stages (Option B)

Two options were considered.

- Option A (bit-reverse wrapper around P1's core): reverse DIN, shift left,
  reverse back. P1's core can only zero-fill, so SRA (sign fill) and ROL
  (wrap-around) would still need extra mask logic or a second pass through the
  core. That gives more hardware and a less clear structure.
- Option B (chosen): each stage selects between pass, shift in the chosen
  direction, and fill/wrap. SRA and ROL fall out naturally: only the fill bit
  and the wrap connection change. The 4-stage structure and the SHAMT-to-stage
  mapping stay exactly as P1 froze them.

To keep P1's frozen interface untouched, the mode-aware stage is a NEW module
(shift_stage_mode) instead of a change to shift_stage. P1's core and testbench
remain in the repo as the regression base (make core).

Hardware estimate: 4 stages x 16 enable MUXes = 64 enable 2:1 MUXes (as in the
core), plus up to 64 small direction/fill/wrap selections and 3 control gates
for the MODE decode. P3 will report exact synthesis numbers.

### 6.5a Interface contract (P2 additions)

Module shift_stage_mode (src/shift_stage_mode.v):

| Item | Name | Width | Direction | Meaning |
|------|------|-------|-----------|---------|
| parameter | SHIFT | - | - | Stage shift amount (1, 2, 4 or 8) |
| port | in | 16 | input | Data into the stage |
| port | sel | 1 | input | Stage enable (a SHAMT bit) |
| port | right | 1 | input | 1 = shift right, 0 = shift left |
| port | rot | 1 | input | 1 = rotate (left only) |
| port | fill | 1 | input | Bit entering from the left on right shifts |
| port | out | 16 | output | Data out of the stage |

Module barrel_shifter16 (src/barrel_shifter16.v):

| Item | Name | Width | Direction | Meaning |
|------|------|-------|-----------|---------|
| port | DIN | 16 | input | Data to be shifted |
| port | SHAMT | 4 | input | Shift amount 0-15 |
| port | MODE | 2 | input | 00 SLL, 01 SRL, 10 SRA, 11 ROL |
| port | DOUT | 16 | output | Shifted / rotated result |

### 6.6 Circuit diagram

See docs/diagrams/complete_circuit.svg (top level: MODE decode + four
shift_stage_mode stages).

### 6.7 Worked examples

Verified results (all four modes):

| DIN | SHAMT | SLL (00) | SRL (01) | SRA (10) | ROL (11) |
|-----|-------|----------|----------|----------|----------|
| 0x8001 | 1 | 0x0002 | 0x4000 | 0xC000 | 0x0003 |
| 0xF0F0 | 4 | 0x0F00 | 0x0F0F | 0xFF0F | 0x0F0F |

Example 1: SRA, DIN = 0x8000, SHAMT = 4 (0100, only stage 3 enabled).
MODE = 10 so right = 1, rot = 0, fill = DIN[15] = 1. Stage 3 shifts right by 4
and fills the top 4 bits with 1:
1000 0000 0000 0000 -> 1111 1000 0000 0000 = 0xF800.
With SRL (fill = 0) the same input would give 0x0800. This is the difference
between SRL and SRA.

Example 2: ROL, DIN = 0xF0F0, SHAMT = 4 (only stage 3 enabled).
MODE = 11 so right = 0, rot = 1. Stage 3 shifts left by 4 and the four bits
that leave on the left (1111) re-enter on the right:
1111 0000 1111 0000 -> 0000 1111 0000 1111 = 0x0F0F.

Example 3: SRL, DIN = 0xF0F0, SHAMT = 13 = 1101 (stages 1, 3, 4 enabled).
Total right shift = 1 + 4 + 8 = 13, zeros enter from the left:
0xF0F0 >> 13 = 0x0007.

### 6.8 Edge cases tested (tb/tb_barrel_shifter.v)

SHAMT = 0 and 15; DIN = 0x0000, 0xFFFF, 0x8000, 0x7FFF, 0xAAAA, 0x5555, 0xF0F0,
0x8001, 0x0001, 0x1234, 0xA5A5 for all 4 modes x all 16 shift amounts (704
directed cases), 12 hand-computed values (including 0x8000 SRA 4 = 0xF800 and
0xF0F0 SRA 4 = 0xFF0F), and 256 random cases. Total 972 tests, all PASS.

## 7. Why this design (P1 explanation)

### Why 4 stages
A 4-bit shift amount can be any number from 0 to 15, and 16 = 2^4, so
log2(16) = 4 stages are enough.

### Why shifts of 1, 2, 4 and 8
Every number from 0 to 15 is a sum of these four values, using each at most
once. That is just its binary representation. So four on/off decisions are
enough to build any shift, instead of 15 separate shift circuits.

### Why one 2:1 MUX per bit per stage
Each output bit of a stage has only two possible sources: its own input bit
(stage OFF) or the bit SHIFT places lower (stage ON). Choosing between two
sources is exactly a 2:1 MUX.

### What a 2:1 MUX does
A 2:1 MUX has two data inputs (A and B), one select line (S) and one output Y.
If S = 0 then Y = A. If S = 1 then Y = B.
In Verilog: assign Y = S ? B : A;

### How a stage is built
A stage has 16 output bits, so it uses 16 MUXes side by side, all sharing the
same select line. For a stage with shift amount SHIFT, output bit i has
A = in[i] and B = in[i - SHIFT]. For the lowest SHIFT bits there is nothing
below to take from, so B = 0 (zero fill).

### Worked example: shift by 13
SHAMT = 13 = 1101 in binary, so SHAMT[3]=1, SHAMT[2]=1, SHAMT[1]=0, SHAMT[0]=1.

| Stage | Shift | Select bit | Enabled? | Action |
|-------|-------|------------|----------|--------|
| 1 | 1 | SHAMT[0] = 1 | yes | shift left by 1 |
| 2 | 2 | SHAMT[1] = 0 | no | pass through |
| 3 | 4 | SHAMT[2] = 1 | yes | shift left by 4 |
| 4 | 8 | SHAMT[3] = 1 | yes | shift left by 8 |

Total shift = 1 + 4 + 8 = 13.

Concrete run with DIN = 0x1234 (0001 0010 0011 0100):
- After stage 1 (x1): 0010 0100 0110 1000 = 0x2468
- After stage 2 (pass): 0x2468
- After stage 3 (x4): 0100 0110 1000 0000 = 0x4680
- After stage 4 (x8): 1000 0000 0000 0000 = 0x8000

DOUT = 0x8000, which matches the testbench result for din=1234 shamt=13.