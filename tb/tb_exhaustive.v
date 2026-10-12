`timescale 1ns/1ps
// tb_exhaustive.v  (P3)
// Exhaustive self-checking testbench for barrel_shifter16:
//   65,536 inputs x 16 shift amounts x 4 modes = 4,194,304 cases.
// Reference model is INDEPENDENT of the DUT and of P2's testbench:
// it shifts ONE bit position at a time, SHAMT times (no <<, >>, >>> operators).
// Define INJECT_BUG (iverilog -DINJECT_BUG) to corrupt one case on purpose and
// prove that this testbench really detects failures.

module tb_exhaustive;
    reg  [15:0] din;
    reg  [3:0]  shamt;
    reg  [1:0]  mode;
    wire [15:0] dout;

    reg  [15:0] got;
    reg  [15:0] expected;
    integer i, s, m;
    integer total, passed, failed;
    integer fail_mode0, fail_mode1, fail_mode2, fail_mode3;

    barrel_shifter16 dut (.DIN(din), .SHAMT(shamt), .MODE(mode), .DOUT(dout));

    // One-bit-at-a-time reference model
    function [15:0] ref_model;
        input [15:0] d;
        input [3:0]  sh;
        input [1:0]  md;
        integer k;
        reg [15:0] r;
        begin
            r = d;
            for (k = 0; k < sh; k = k + 1) begin
                case (md)
                    2'b00:   r = {r[14:0], 1'b0};    // SLL
                    2'b01:   r = {1'b0, r[15:1]};    // SRL
                    2'b10:   r = {r[15], r[15:1]};   // SRA
                    default: r = {r[14:0], r[15]};   // ROL
                endcase
            end
            ref_model = r;
        end
    endfunction

    initial begin
        total = 0; passed = 0; failed = 0;
        fail_mode0 = 0; fail_mode1 = 0; fail_mode2 = 0; fail_mode3 = 0;

        for (m = 0; m < 4; m = m + 1)
            for (s = 0; s < 16; s = s + 1)
                for (i = 0; i < 65536; i = i + 1) begin
                    din = i; shamt = s; mode = m;
                    #1;
                    got = dout;
`ifdef INJECT_BUG
                    // deliberate fault: SRA with shamt = 5 gets its LSB flipped
                    if (mode == 2'b10 && shamt == 4'd5) got = dout ^ 16'h0001;
`endif
                    expected = ref_model(din, shamt, mode);
                    total = total + 1;
                    if (got === expected) passed = passed + 1;
                    else begin
                        failed = failed + 1;
                        case (mode)
                            2'b00: fail_mode0 = fail_mode0 + 1;
                            2'b01: fail_mode1 = fail_mode1 + 1;
                            2'b10: fail_mode2 = fail_mode2 + 1;
                            default: fail_mode3 = fail_mode3 + 1;
                        endcase
                        if (failed <= 20)
                            $display("FAIL: mode=%b shamt=%0d din=%h got=%h expected=%h",
                                     mode, shamt, din, got, expected);
                    end
                end

        $display("======================================");
        $display("Exhaustive test: 65536 inputs x 16 shifts x 4 modes");
        $display("Total tests : %0d", total);
        $display("Passed      : %0d", passed);
        $display("Failed      : %0d", failed);
        $display("  failures by mode: SLL=%0d SRL=%0d SRA=%0d ROL=%0d",
                 fail_mode0, fail_mode1, fail_mode2, fail_mode3);
        $display("======================================");
        if (failed == 0) $display("RESULT: ALL TESTS PASSED");
        else             $display("RESULT: SOME TESTS FAILED");
        $finish;
    end
endmodule
