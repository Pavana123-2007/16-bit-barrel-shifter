# Makefile for 16-bit barrel shifter
# Targets: core (P1), sim (P2), exhaustive + bugtest + wave (P3), test, clean

SRC_CORE = src/shift_stage.v src/barrel_core.v
SRC_TOP  = src/shift_stage_mode.v src/barrel_shifter16.v

ifeq ($(OS),Windows_NT)
CLEAN_CMD = del /q *.out *.vcd
else
CLEAN_CMD = rm -f *.out *.vcd
endif

.PHONY: core sim exhaustive bugtest wave test clean

# P1: basic core testbench (128 tests)
core:
	iverilog -Wall -o core_sim.out $(SRC_CORE) tb/tb_core.v
	vvp core_sim.out

# P2: self-checking testbench for the complete shifter (972 tests)
sim:
	iverilog -Wall -o sim_bs.out $(SRC_TOP) tb/tb_barrel_shifter.v
	vvp sim_bs.out

# P3: exhaustive testbench, 4,194,304 tests (takes about 2 minutes)
exhaustive:
	iverilog -o exh.out $(SRC_TOP) tb/tb_exhaustive.v
	vvp exh.out

# P3: bug-injection check, this run MUST report failures (65,536 in SRA)
bugtest:
	iverilog -DINJECT_BUG -o exh_bug.out $(SRC_TOP) tb/tb_exhaustive.v
	vvp exh_bug.out

# P3: directed run that writes simulation/waveforms/barrel.vcd for GTKWave
wave:
	iverilog -o wave.out $(SRC_TOP) tb/tb_waveform.v
	vvp wave.out

# All three testbenches in order
test: core sim exhaustive

clean:
	$(CLEAN_CMD)
