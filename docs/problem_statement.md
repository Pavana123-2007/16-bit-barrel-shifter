# Problem Statement

## Title

Design and implementation of a 16-bit barrel shifter.

## Problem

In a processor, shifting a word by n positions one step at a time would take
n clock cycles. A barrel shifter is a combinational circuit that shifts or
rotates a word by any amount in a single step, with no clock and no state
machine. It is used inside the ALU of almost every CPU.

The task is to design, implement and verify a 16-bit barrel shifter in Verilog
using a staged multiplexer (MUX) architecture.

## Inputs and outputs

| Signal | Width | Direction | Meaning |
|--------|-------|-----------|---------|
| DIN | 16 | input | Data to be shifted |
| SHAMT | 4 | input | Shift amount, 0 to 15 |
| MODE | 2 | input | Operation select (added in the complete design) |
| DOUT | 16 | output | Shifted or rotated result |

## Required operations (complete design)

| MODE | Operation | Behaviour |
|------|-----------|-----------|
| 00 | Logical left shift (SLL) | Zeros enter from the right |
| 01 | Logical right shift (SRL) | Zeros enter from the left |
| 10 | Arithmetic right shift (SRA) | Sign bit DIN[15] is replicated on the left |
| 11 | Rotate left (ROL) | Bits shifted out on the left re-enter on the right |

## Design constraints

- Purely combinational: no clock, no FSM.
- Staged logarithmic architecture: 4 stages of 16 two-to-one MUXes,
  shifting by 1, 2, 4 and 8, controlled by the 4 bits of SHAMT.
- Written in synthesizable Verilog (plain Verilog-2001).

## Scope of the first milestone (v0.1-core)

The core supports logical left shift with zero fill only. The remaining
operations and the MODE input are added in the next milestone.

## Objectives

1. Build a working 4-stage MUX core that shifts by any amount 0 to 15.
2. Extend it to all four operations.
3. Verify it with a self-checking testbench and an exhaustive test of all
   4,194,304 input combinations.
4. Show the hardware structure and justify the architecture.

