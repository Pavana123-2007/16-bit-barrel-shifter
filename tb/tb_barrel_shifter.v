`timescale 1ns/1ps
// tb_barrel_shifter.v  (P2)
// Self-checking testbench for barrel_shifter16.
// Reference model: behavioural operators. Also checks hand-computed values.

module tb_barrel_shifter;
    reg  [15:0] DIN;
    reg  [3:0]  SHAMT;
    reg  [1:0]  MODE;
    wire [15:0] DOUT;

    reg  [15:0] expected;
    reg  [15:0] pattern;
    reg  [31:0] rnd;
    integer pass_count;
    integer fail_count;
    integer total_count;
    integer p;
    integer m;
    integer s;
    integer r;

    barrel_shifter16 dut (.DIN(DIN), .SHAMT(SHAMT), .MODE(MODE), .DOUT(DOUT));

    // Reference model using Verilog operators
    function [15:0] model;
        input [15:0] fd;
        input [3:0]  fs;
        input [1:0]  fm;
        reg signed [15:0] sd;
        begin
            case (fm)
                2'b00: model = fd << fs;
                2'b01: model = fd >> fs;
                2'b10: begin
                           sd    = fd;
                           model = sd >>> fs;
                       end
                default: begin
                           if (fs == 0) model = fd;
                           else         model = (fd << fs) | (fd >> (16 - fs));
                       end
            endcase
        end
    endfunction

    // Apply one case, compare DOUT with the model
    task check;
        input [15:0] d;
        input [3:0]  sh;
        input [1:0]  mo;
        input        verbose;
        begin
            DIN = d; SHAMT = sh; MODE = mo;
            #10;
            expected    = model(d, sh, mo);
            total_count = total_count + 1;
            if (DOUT === expected) begin
                pass_count = pass_count + 1;
                if (verbose)
                    $display("PASS: mode=%b shamt=%0d din=%h got=%h exp=%h", mo, sh, d, DOUT, expected);
            end else begin
                fail_count = fail_count + 1;
                $display("FAIL: mode=%b shamt=%0d din=%h got=%h exp=%h", mo, sh, d, DOUT, expected);
            end
        end
    endtask

    // Apply one case, compare with a hand-computed value
    task check_known;
        input [15:0] d;
        input [3:0]  sh;
        input [1:0]  mo;
        input [15:0] known;
        begin
            DIN = d; SHAMT = sh; MODE = mo;
            #10;
            total_count = total_count + 1;
            if (DOUT === known) begin
                pass_count = pass_count + 1;
                $display("PASS: (known) mode=%b shamt=%0d din=%h got=%h exp=%h", mo, sh, d, DOUT, known);
            end else begin
                fail_count = fail_count + 1;
                $display("FAIL: (known) mode=%b shamt=%0d din=%h got=%h exp=%h", mo, sh, d, DOUT, known);
            end
        end
    endtask

    initial begin
        pass_count  = 0;
        fail_count  = 0;
        total_count = 0;

        $display("---- Hand-computed values (spec table + edge cases) ----");
        check_known(16'h8001, 4'd1, 2'b00, 16'h0002);
        check_known(16'h8001, 4'd1, 2'b01, 16'h4000);
        check_known(16'h8001, 4'd1, 2'b10, 16'hC000);
        check_known(16'h8001, 4'd1, 2'b11, 16'h0003);
        check_known(16'hF0F0, 4'd4, 2'b00, 16'h0F00);
        check_known(16'hF0F0, 4'd4, 2'b01, 16'h0F0F);
        check_known(16'hF0F0, 4'd4, 2'b10, 16'hFF0F);
        check_known(16'hF0F0, 4'd4, 2'b11, 16'h0F0F);
        check_known(16'h8000, 4'd4, 2'b10, 16'hF800);
        check_known(16'h7FFF, 4'd4, 2'b10, 16'h07FF);
        check_known(16'hFFFF, 4'd15, 2'b10, 16'hFFFF);
        check_known(16'h8000, 4'd1, 2'b11, 16'h0001);

        $display("---- Directed: all 4 modes x all 16 shifts x edge patterns ----");
        for (p = 0; p < 11; p = p + 1) begin
            case (p)
                0:  pattern = 16'h0000;
                1:  pattern = 16'hFFFF;
                2:  pattern = 16'h8000;
                3:  pattern = 16'h7FFF;
                4:  pattern = 16'hAAAA;
                5:  pattern = 16'h5555;
                6:  pattern = 16'hF0F0;
                7:  pattern = 16'h8001;
                8:  pattern = 16'h0001;
                9:  pattern = 16'h1234;
                default: pattern = 16'hA5A5;
            endcase
            for (m = 0; m < 4; m = m + 1)
                for (s = 0; s < 16; s = s + 1)
                    check(pattern, s, m, 1);
        end

        $display("---- Random: 256 cases (only FAILs are printed) ----");
        for (r = 0; r < 256; r = r + 1) begin
            rnd = $random;
            check(rnd[15:0], rnd[19:16], rnd[21:20], 0);
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
