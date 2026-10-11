`timescale 1ns/1ps
// barrel_shifter16.v  (P2)
// Final top-level: 16-bit barrel shifter, 4 operations selected by MODE.
//   MODE 00 SLL  logical left shift, zero fill
//   MODE 01 SRL  logical right shift, zero fill
//   MODE 10 SRA  arithmetic right shift, fill = DIN[15]
//   MODE 11 ROL  rotate left, bits leaving the left re-enter on the right
// Purely combinational (no FSM). Same 4-stage structure as P1's core:
// SHAMT[0] -> x1, SHAMT[1] -> x2, SHAMT[2] -> x4, SHAMT[3] -> x8.

module barrel_shifter16 (
    input  [15:0] DIN,
    input  [3:0]  SHAMT,
    input  [1:0]  MODE,
    output [15:0] DOUT
);
    // Control decode from MODE
    wire right = MODE[1] ^ MODE[0];                // 01 or 10 -> right shift
    wire rot   = MODE[1] & MODE[0];                // 11       -> rotate
    wire fill  = MODE[1] & ~MODE[0] & DIN[15];     // 10       -> sign bit

    wire [15:0] s1, s2, s3;

    shift_stage_mode #(.SHIFT(1)) stage1 (.in(DIN), .sel(SHAMT[0]), .right(right), .rot(rot), .fill(fill), .out(s1));
    shift_stage_mode #(.SHIFT(2)) stage2 (.in(s1),  .sel(SHAMT[1]), .right(right), .rot(rot), .fill(fill), .out(s2));
    shift_stage_mode #(.SHIFT(4)) stage3 (.in(s2),  .sel(SHAMT[2]), .right(right), .rot(rot), .fill(fill), .out(s3));
    shift_stage_mode #(.SHIFT(8)) stage4 (.in(s3),  .sel(SHAMT[3]), .right(right), .rot(rot), .fill(fill), .out(DOUT));
endmodule
