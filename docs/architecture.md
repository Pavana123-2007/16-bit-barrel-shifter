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

(P2: add the complete design, MODE table and circuit diagram below.)

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