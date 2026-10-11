# Makefile for 16-bit barrel shifter
# Targets: core (P1), sim (P2), test, clean   (P3 adds exhaustive)

SRC_CORE = src/shift_stage.v src/barrel_core.v
SRC_TOP  = src/shift_stage_mode.v src/barrel_shifter16.v

ifeq ($(OS),Windows_NT)
CLEAN_CMD = del /q *.out *.vcd
else
CLEAN_CMD = rm -f *.out *.vcd
endif

.PHONY: core sim test clean

core:
	iverilog -Wall -o core_sim.out $(SRC_CORE) tb/tb_core.v
	vvp core_sim.out

sim:
	iverilog -Wall -o sim_bs.out $(SRC_TOP) tb/tb_barrel_shifter.v
	vvp sim_bs.out

test: core sim

clean:
	$(CLEAN_CMD)
