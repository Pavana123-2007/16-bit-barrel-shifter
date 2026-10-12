`timescale 1ns/1ps
// tb_waveform.v  (P3)
// Small directed run that writes a VCD for GTKWave screenshots.
// (Not the exhaustive run: that would create a gigantic VCD.)

module tb_waveform;
    reg  [15:0] din;
    reg  [3:0]  shamt;
    reg  [1:0]  mode;
    wire [15:0] dout;

    barrel_shifter16 dut (.DIN(din), .SHAMT(shamt), .MODE(mode), .DOUT(dout));

    initial begin
        $dumpfile("simulation/waveforms/barrel.vcd");
        $dumpvars(0, tb_waveform);
        $monitor("t=%0t mode=%b shamt=%0d din=%h dout=%h", $time, mode, shamt, din, dout);

        // 0x8001 shifted by 1: expect 0002, 4000, C000, 0003
        din = 16'h8001; shamt = 4'd1; mode = 2'b00; #20;
        mode = 2'b01; #20;
        mode = 2'b10; #20;
        mode = 2'b11; #20;

        // 0xF0F0 shifted by 4: expect 0F00, 0F0F, FF0F, 0F0F
        din = 16'hF0F0; shamt = 4'd4; mode = 2'b00; #20;
        mode = 2'b01; #20;
        mode = 2'b10; #20;
        mode = 2'b11; #20;

        // Edge cases
        din = 16'h8000; shamt = 4'd15; mode = 2'b10; #20;  // SRA: FFFF
        din = 16'h8000; shamt = 4'd15; mode = 2'b01; #20;  // SRL: 0001
        din = 16'hFFFF; shamt = 4'd0;  mode = 2'b11; #20;  // shift 0: FFFF
        din = 16'h1234; shamt = 4'd13; mode = 2'b00; #20;  // 13 = 8+4+1: 8000
        $finish;
    end
endmodule
