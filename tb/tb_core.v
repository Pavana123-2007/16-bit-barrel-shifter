// tb_core.v
// Basic testbench for barrel_core (logical left shift, zero fill).
// Reference model: the behavioural << operator.

`timescale 1ns/1ps

module tb_core;
    reg  [15:0] DIN;
    reg  [3:0]  SHAMT;
    wire [15:0] DOUT;

    reg  [15:0] expected;
    integer pass_count;
    integer fail_count;
    integer total_count;
    integer k;
    integer p;
    reg  [15:0] pattern;

    barrel_core dut (.DIN(DIN), .SHAMT(SHAMT), .DOUT(DOUT));

    // Apply one case, compare with the << operator, print PASS/FAIL
    task check;
        input [15:0] d;
        input [3:0]  s;
        input        verbose;
        begin
            DIN   = d;
            SHAMT = s;
            #10;
            expected = d << s;
            total_count = total_count + 1;
            if (DOUT === expected) begin
                pass_count = pass_count + 1;
                if (verbose)
                    $display("PASS: din=%h shamt=%0d dout=%h", d, s, DOUT);
            end else begin
                fail_count = fail_count + 1;
                $display("FAIL: din=%h shamt=%0d got=%h exp=%h", d, s, DOUT, expected);
            end
        end
    endtask

    initial begin
        pass_count  = 0;
        fail_count  = 0;
        total_count = 0;

        $display("---- Directed: key shift amounts on 0x0001 ----");
        check(16'h0001, 4'd0,  1);
        check(16'h0001, 4'd1,  1);
        check(16'h0001, 4'd2,  1);
        check(16'h0001, 4'd4,  1);
        check(16'h0001, 4'd8,  1);
        check(16'h0001, 4'd15, 1);

        $display("---- Directed: different patterns ----");
        check(16'h8000, 4'd1,  1);
        check(16'hA5A5, 4'd4,  1);
        check(16'h5555, 4'd3,  1);
        check(16'h1234, 4'd8,  1);
        check(16'h1234, 4'd13, 1);

        $display("---- Directed: all-zero and all-one inputs ----");
        check(16'h0000, 4'd0,  1);
        check(16'h0000, 4'd15, 1);
        check(16'hFFFF, 4'd0,  1);
        check(16'hFFFF, 4'd7,  1);
        check(16'hFFFF, 4'd15, 1);

        $display("---- Sweep: all 16 shift amounts for several patterns ----");
        for (p = 0; p < 7; p = p + 1) begin
            case (p)
                0: pattern = 16'h0001;
                1: pattern = 16'h8000;
                2: pattern = 16'hA5A5;
                3: pattern = 16'h5555;
                4: pattern = 16'h1234;
                5: pattern = 16'h0000;
                default: pattern = 16'hFFFF;
            endcase
            for (k = 0; k < 16; k = k + 1)
                check(pattern, k, 1);
        end

        $display("----------------------------------------");
        $display("Total tests : %0d", total_count);
        $display("Passed      : %0d", pass_count);
        $display("Failed      : %0d", fail_count);
        if (fail_count == 0)
            $display("RESULT: ALL TESTS PASSED");
        else
            $display("RESULT: SOME TESTS FAILED");
        $finish;
    end
endmodule