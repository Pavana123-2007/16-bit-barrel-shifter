`timescale 1ns/1ps
	// shift_stage.v
// One stage of the barrel shifter: 16 x 2:1 MUX.
// sel = 0 : out = in               (pass through)
// sel = 1 : out = in << SHIFT      (logical left shift, zero fill)
// Written as visible MUXes (conditional expressions), not with the << operator.

module shift_stage (in, sel, out);
    parameter SHIFT = 1;

    input  [15:0] in;
    input         sel;
    output [15:0] out;

    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin : bit_mux
            if (i >= SHIFT) begin : shifted
                // MUX: choose own bit (sel=0) or bit SHIFT places lower (sel=1)
                assign out[i] = sel ? in[i - SHIFT] : in[i];
            end else begin : zero_fill
                // No bit to take from below: zero enters here when sel=1
                assign out[i] = sel ? 1'b0 : in[i];
            end
        end
    endgenerate
endmodule