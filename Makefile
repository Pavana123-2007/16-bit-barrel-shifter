# Makefile for 16-bit barrel shifter
# Targets: core, test, clean (P2 adds sim, P3 adds exhaustive)

SRC_CORE = src/shift_stage.v src/barrel_core.v

.PHONY: core test clean

core:
	iverilog -Wall -o core_sim.out $(SRC_CORE) tb/tb_core.v
	vvp core_sim.out

test: core

clean:
	del /q *.out *.vcd