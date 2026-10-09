`timescale 1ns/1ps
// barrel_core.v
// 16-bit barrel shifter core: 4 stages chained in series.
// Logical left shift by SHAMT (0-15), zero fill.
//   Stage 1: shift by 1, select = SHAMT[0]
//   Stage 2: shift by 2, select = SHAMT[1]
//   Stage 3: shift by 4, select = SHAMT[2]
//   Stage 4: shift by 8, select = SHAMT[3]

module barrel_core (DIN, SHAMT, DOUT);
    input  [15:0] DIN;
    input  [3:0]  SHAMT;
    output [15:0] DOUT;

    wire [15:0] s1, s2, s3;

    shift_stage #(.SHIFT(1)) stage1 (.in(DIN), .sel(SHAMT[0]), .out(s1));
    shift_stage #(.SHIFT(2)) stage2 (.in(s1),  .sel(SHAMT[1]), .out(s2));
    shift_stage #(.SHIFT(4)) stage3 (.in(s2),  .sel(SHAMT[2]), .out(s3));
    shift_stage #(.SHIFT(8)) stage4 (.in(s3),  .sel(SHAMT[3]), .out(DOUT));
endmodule