`timescale 1ns/1ps
// shift_stage_mode.v  (P2)
// Mode-aware version of P1's shift_stage: one stage = 16 x 2:1 MUX with
// direction, rotate and fill control. Written as visible conditional
// expressions, not with the shift operators.
//   sel = 0          : out = in                      (pass through)
//   sel = 1, left    : out[i] = in[i-SHIFT]          (SLL / ROL)
//                      low SHIFT bits: 0 (SLL) or wrapped bit (ROL, rot = 1)
//   sel = 1, right   : out[i] = in[i+SHIFT]          (SRL / SRA)
//                      top SHIFT bits: fill (0 for SRL, DIN[15] for SRA)

module shift_stage_mode (in, sel, right, rot, fill, out);
    parameter SHIFT = 1;

    input  [15:0] in;
    input         sel;     // stage enable (a SHAMT bit)
    input         right;   // 1 = shift right, 0 = shift left
    input         rot;     // 1 = rotate (only meaningful for left)
    input         fill;    // bit entering from the left on right shifts
    output [15:0] out;

    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin : bit_mux
            if (i >= SHIFT && (i + SHIFT) <= 15) begin : both_sources
                assign out[i] = sel ? (right ? in[i + SHIFT] : in[i - SHIFT]) : in[i];
            end else if (i >= SHIFT) begin : top_bits
                // right shift: nothing above, so fill enters here
                assign out[i] = sel ? (right ? fill : in[i - SHIFT]) : in[i];
            end else begin : low_bits
                // left shift: nothing below, so 0 (SLL) or wrapped bit (ROL)
                assign out[i] = sel ? (right ? in[i + SHIFT]
                                             : (rot ? in[i - SHIFT + 16] : 1'b0))
                                    : in[i];
            end
        end
    endgenerate
endmodule
