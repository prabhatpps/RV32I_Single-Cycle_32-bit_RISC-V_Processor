#=====================================================================
# Makefile : RV32I Single-Cycle RISC-V Processor — Regression Suite
# Author   : Prabhat Pandey
# Project  : RV32I_Single-Cycle_32-bit_RISC-V_Processor
#
# Run from the project root directory.
#
# Targets:
#   all      — Compile + run all testbenches + print summary (default)
#   compile  — Compile all testbenches only (no simulation)
#   run      — Compile + run all testbenches (no summary)
#   summary  — Print pass/fail summary from existing log files
#   clean    — Remove all generated binaries, logs, and VCDs
#
# Individual testbench targets (compile + simulate that one bench):
#   tb_alu                              tb_alu_control
#   tb_branch_unit                      tb_decoder_controller
#   tb_dmem                             tb_imem_program_1
#   tb_imem_program_2                   tb_imm_gen
#   tb_pc_next_logic                    tb_pc_reg
#   tb_regfile                          tb_wb_mux
#   tb_riscv32_singlecycle_top_program_1
#   tb_riscv32_singlecycle_top_program_2
#
# Output layout inside Verification_Results/:
#   result_tb_*           iverilog simulation binaries
#   *.vcd                 VCD waveform files (open with GTKWave)
#   logs/tb_*.log         Full simulation transcript per testbench
#=====================================================================

SHELL    := /bin/bash
IVERILOG := iverilog
VVP      := vvp

ROOT     := $(CURDIR)
SRC      := $(ROOT)/src
TB       := $(ROOT)/RTL_Verification
OUT      := $(ROOT)/Verification_Results
LOGS     := $(OUT)/logs
VCD      := $(OUT)/vcd

SRC_ALL  := $(wildcard $(SRC)/*.v)

#---------------------------------------------------------------------
# Simulation binary paths
#---------------------------------------------------------------------
BIN_ALU      := $(OUT)/result_tb_alu
BIN_ALU_CTRL := $(OUT)/result_tb_alu_control
BIN_BRANCH   := $(OUT)/result_tb_branch_unit
BIN_DECODER  := $(OUT)/result_tb_decoder_controller
BIN_DMEM     := $(OUT)/result_tb_dmem
BIN_IMEM_P1  := $(OUT)/result_tb_imem_program_1
BIN_IMEM_P2  := $(OUT)/result_tb_imem_program_2
BIN_IMM_GEN  := $(OUT)/result_tb_imm_gen
BIN_PC_NEXT  := $(OUT)/result_tb_pc_next_logic
BIN_PC_REG   := $(OUT)/result_tb_pc_reg
BIN_REGFILE  := $(OUT)/result_tb_regfile
BIN_WB_MUX   := $(OUT)/result_tb_wb_mux
BIN_TOP_P1   := $(OUT)/result_tb_top_program_1
BIN_TOP_P2   := $(OUT)/result_tb_top_program_2

ALL_BINS := \
	$(BIN_ALU)     $(BIN_ALU_CTRL) $(BIN_BRANCH)  $(BIN_DECODER) \
	$(BIN_DMEM)    $(BIN_IMEM_P1)  $(BIN_IMEM_P2) $(BIN_IMM_GEN) \
	$(BIN_PC_NEXT) $(BIN_PC_REG)   $(BIN_REGFILE) $(BIN_WB_MUX)  \
	$(BIN_TOP_P1)  $(BIN_TOP_P2)

#---------------------------------------------------------------------
# Simulation log paths
#---------------------------------------------------------------------
LOG_ALU      := $(LOGS)/tb_alu.log
LOG_ALU_CTRL := $(LOGS)/tb_alu_control.log
LOG_BRANCH   := $(LOGS)/tb_branch_unit.log
LOG_DECODER  := $(LOGS)/tb_decoder_controller.log
LOG_DMEM     := $(LOGS)/tb_dmem.log
LOG_IMEM_P1  := $(LOGS)/tb_imem_program_1.log
LOG_IMEM_P2  := $(LOGS)/tb_imem_program_2.log
LOG_IMM_GEN  := $(LOGS)/tb_imm_gen.log
LOG_PC_NEXT  := $(LOGS)/tb_pc_next_logic.log
LOG_PC_REG   := $(LOGS)/tb_pc_reg.log
LOG_REGFILE  := $(LOGS)/tb_regfile.log
LOG_WB_MUX   := $(LOGS)/tb_wb_mux.log
LOG_TOP_P1   := $(LOGS)/tb_riscv32_singlecycle_top_program_1.log
LOG_TOP_P2   := $(LOGS)/tb_riscv32_singlecycle_top_program_2.log

ALL_LOGS := \
	$(LOG_ALU)     $(LOG_ALU_CTRL) $(LOG_BRANCH)  $(LOG_DECODER) \
	$(LOG_DMEM)    $(LOG_IMEM_P1)  $(LOG_IMEM_P2) $(LOG_IMM_GEN) \
	$(LOG_PC_NEXT) $(LOG_PC_REG)   $(LOG_REGFILE) $(LOG_WB_MUX)  \
	$(LOG_TOP_P1)  $(LOG_TOP_P2)

#=====================================================================
# Default target
#=====================================================================
.PHONY: all
all: $(LOGS) $(VCD) compile run summary

#=====================================================================
# Directory creation
#=====================================================================
$(LOGS):
	@mkdir -p $(LOGS)

$(VCD):
	@mkdir -p $(VCD)

#=====================================================================
# compile — build all simulation binaries
#=====================================================================
.PHONY: compile
compile: $(ALL_BINS)

#---------------------------------------------------------------------
# Unit-level testbench compile rules
#---------------------------------------------------------------------
$(BIN_ALU): $(SRC)/alu.v $(TB)/tb_alu.v
	@echo "[COMPILE] tb_alu"
	@$(IVERILOG) -o $@ $(SRC)/alu.v $(TB)/tb_alu.v

$(BIN_ALU_CTRL): $(SRC)/alu_control.v $(TB)/tb_alu_control.v
	@echo "[COMPILE] tb_alu_control"
	@$(IVERILOG) -o $@ $(SRC)/alu_control.v $(TB)/tb_alu_control.v

$(BIN_BRANCH): $(SRC)/branch_unit.v $(TB)/tb_branch_unit.v
	@echo "[COMPILE] tb_branch_unit"
	@$(IVERILOG) -o $@ $(SRC)/branch_unit.v $(TB)/tb_branch_unit.v

$(BIN_DECODER): $(SRC)/decoder_controller.v $(TB)/tb_decoder_controller.v
	@echo "[COMPILE] tb_decoder_controller"
	@$(IVERILOG) -o $@ $(SRC)/decoder_controller.v $(TB)/tb_decoder_controller.v

$(BIN_DMEM): $(SRC)/dmem.v $(TB)/tb_dmem.v
	@echo "[COMPILE] tb_dmem"
	@$(IVERILOG) -o $@ $(SRC)/dmem.v $(TB)/tb_dmem.v

$(BIN_IMEM_P1): $(SRC)/imem.v $(TB)/tb_imem_program_1.v
	@echo "[COMPILE] tb_imem_program_1"
	@$(IVERILOG) -o $@ $(SRC)/imem.v $(TB)/tb_imem_program_1.v

$(BIN_IMEM_P2): $(SRC)/imem.v $(TB)/tb_imem_program_2.v
	@echo "[COMPILE] tb_imem_program_2"
	@$(IVERILOG) -o $@ $(SRC)/imem.v $(TB)/tb_imem_program_2.v

$(BIN_IMM_GEN): $(SRC)/imm_gen.v $(TB)/tb_imm_gen.v
	@echo "[COMPILE] tb_imm_gen"
	@$(IVERILOG) -o $@ $(SRC)/imm_gen.v $(TB)/tb_imm_gen.v

$(BIN_PC_NEXT): $(SRC)/pc_next_logic.v $(TB)/tb_pc_next_logic.v
	@echo "[COMPILE] tb_pc_next_logic"
	@$(IVERILOG) -o $@ $(SRC)/pc_next_logic.v $(TB)/tb_pc_next_logic.v

$(BIN_PC_REG): $(SRC)/pc_reg.v $(TB)/tb_pc_reg.v
	@echo "[COMPILE] tb_pc_reg"
	@$(IVERILOG) -o $@ $(SRC)/pc_reg.v $(TB)/tb_pc_reg.v

$(BIN_REGFILE): $(SRC)/regfile.v $(TB)/tb_regfile.v
	@echo "[COMPILE] tb_regfile"
	@$(IVERILOG) -o $@ $(SRC)/regfile.v $(TB)/tb_regfile.v

$(BIN_WB_MUX): $(SRC)/wb_mux.v $(TB)/tb_wb_mux.v
	@echo "[COMPILE] tb_wb_mux"
	@$(IVERILOG) -o $@ $(SRC)/wb_mux.v $(TB)/tb_wb_mux.v

#---------------------------------------------------------------------
# Top-level testbench compile rules (include all RTL sources)
#---------------------------------------------------------------------
$(BIN_TOP_P1): $(SRC_ALL) $(TB)/tb_riscv32_singlecycle_top_program_1.v
	@echo "[COMPILE] tb_riscv32_singlecycle_top_program_1"
	@$(IVERILOG) -o $@ $(SRC_ALL) $(TB)/tb_riscv32_singlecycle_top_program_1.v

$(BIN_TOP_P2): $(SRC_ALL) $(TB)/tb_riscv32_singlecycle_top_program_2.v
	@echo "[COMPILE] tb_riscv32_singlecycle_top_program_2"
	@$(IVERILOG) -o $@ $(SRC_ALL) $(TB)/tb_riscv32_singlecycle_top_program_2.v

#=====================================================================
# run — simulate all testbenches and capture logs
#=====================================================================
.PHONY: run
run: $(LOGS) $(VCD) compile $(ALL_LOGS)

# Macro: compile a single log from a simulation binary.
# $(1) = log file path   $(2) = binary path
define SIM_RULE
$(1): $(2) | $(LOGS) $(VCD)
	@printf "[RUN]     %-55s " "$(notdir $(2))"
	@$(VVP) $(2) > $(1) 2>&1; \
	if grep -q "STATUS: ALL TESTS PASSED" $(1); then \
		echo "PASS"; \
	elif grep -q "STATUS: SOME TESTS FAILED" $(1); then \
		echo "FAIL"; \
	else \
		echo "ERROR"; \
	fi
endef

$(eval $(call SIM_RULE,$(LOG_ALU),$(BIN_ALU)))
$(eval $(call SIM_RULE,$(LOG_ALU_CTRL),$(BIN_ALU_CTRL)))
$(eval $(call SIM_RULE,$(LOG_BRANCH),$(BIN_BRANCH)))
$(eval $(call SIM_RULE,$(LOG_DECODER),$(BIN_DECODER)))
$(eval $(call SIM_RULE,$(LOG_DMEM),$(BIN_DMEM)))
$(eval $(call SIM_RULE,$(LOG_IMEM_P1),$(BIN_IMEM_P1)))
$(eval $(call SIM_RULE,$(LOG_IMEM_P2),$(BIN_IMEM_P2)))
$(eval $(call SIM_RULE,$(LOG_IMM_GEN),$(BIN_IMM_GEN)))
$(eval $(call SIM_RULE,$(LOG_PC_NEXT),$(BIN_PC_NEXT)))
$(eval $(call SIM_RULE,$(LOG_PC_REG),$(BIN_PC_REG)))
$(eval $(call SIM_RULE,$(LOG_REGFILE),$(BIN_REGFILE)))
$(eval $(call SIM_RULE,$(LOG_WB_MUX),$(BIN_WB_MUX)))
$(eval $(call SIM_RULE,$(LOG_TOP_P1),$(BIN_TOP_P1)))
$(eval $(call SIM_RULE,$(LOG_TOP_P2),$(BIN_TOP_P2)))

#=====================================================================
# Individual convenience targets — compile + simulate one testbench
#=====================================================================
.PHONY: tb_alu
tb_alu: $(BIN_ALU) $(LOGS)
	@printf "[RUN]     %-55s " "result_tb_alu"
	@$(VVP) $(BIN_ALU) > $(LOG_ALU) 2>&1; \
	if grep -q "STATUS: ALL TESTS PASSED" $(LOG_ALU); then echo "PASS"; \
	elif grep -q "STATUS: SOME TESTS FAILED" $(LOG_ALU); then echo "FAIL"; \
	else echo "ERROR"; fi
	@echo "  → Log: $(LOG_ALU)"

.PHONY: tb_alu_control
tb_alu_control: $(BIN_ALU_CTRL) $(LOGS)
	@printf "[RUN]     %-55s " "result_tb_alu_control"
	@$(VVP) $(BIN_ALU_CTRL) > $(LOG_ALU_CTRL) 2>&1; \
	if grep -q "STATUS: ALL TESTS PASSED" $(LOG_ALU_CTRL); then echo "PASS"; \
	elif grep -q "STATUS: SOME TESTS FAILED" $(LOG_ALU_CTRL); then echo "FAIL"; \
	else echo "ERROR"; fi
	@echo "  → Log: $(LOG_ALU_CTRL)"

.PHONY: tb_branch_unit
tb_branch_unit: $(BIN_BRANCH) $(LOGS)
	@printf "[RUN]     %-55s " "result_tb_branch_unit"
	@$(VVP) $(BIN_BRANCH) > $(LOG_BRANCH) 2>&1; \
	if grep -q "STATUS: ALL TESTS PASSED" $(LOG_BRANCH); then echo "PASS"; \
	elif grep -q "STATUS: SOME TESTS FAILED" $(LOG_BRANCH); then echo "FAIL"; \
	else echo "ERROR"; fi
	@echo "  → Log: $(LOG_BRANCH)"

.PHONY: tb_decoder_controller
tb_decoder_controller: $(BIN_DECODER) $(LOGS)
	@printf "[RUN]     %-55s " "result_tb_decoder_controller"
	@$(VVP) $(BIN_DECODER) > $(LOG_DECODER) 2>&1; \
	if grep -q "STATUS: ALL TESTS PASSED" $(LOG_DECODER); then echo "PASS"; \
	elif grep -q "STATUS: SOME TESTS FAILED" $(LOG_DECODER); then echo "FAIL"; \
	else echo "ERROR"; fi
	@echo "  → Log: $(LOG_DECODER)"

.PHONY: tb_dmem
tb_dmem: $(BIN_DMEM) $(LOGS)
	@printf "[RUN]     %-55s " "result_tb_dmem"
	@$(VVP) $(BIN_DMEM) > $(LOG_DMEM) 2>&1; \
	if grep -q "STATUS: ALL TESTS PASSED" $(LOG_DMEM); then echo "PASS"; \
	elif grep -q "STATUS: SOME TESTS FAILED" $(LOG_DMEM); then echo "FAIL"; \
	else echo "ERROR"; fi
	@echo "  → Log: $(LOG_DMEM)"

.PHONY: tb_imem_program_1
tb_imem_program_1: $(BIN_IMEM_P1) $(LOGS)
	@printf "[RUN]     %-55s " "result_tb_imem_program_1"
	@$(VVP) $(BIN_IMEM_P1) > $(LOG_IMEM_P1) 2>&1; \
	if grep -q "STATUS: ALL TESTS PASSED" $(LOG_IMEM_P1); then echo "PASS"; \
	elif grep -q "STATUS: SOME TESTS FAILED" $(LOG_IMEM_P1); then echo "FAIL"; \
	else echo "ERROR"; fi
	@echo "  → Log: $(LOG_IMEM_P1)"

.PHONY: tb_imem_program_2
tb_imem_program_2: $(BIN_IMEM_P2) $(LOGS)
	@printf "[RUN]     %-55s " "result_tb_imem_program_2"
	@$(VVP) $(BIN_IMEM_P2) > $(LOG_IMEM_P2) 2>&1; \
	if grep -q "STATUS: ALL TESTS PASSED" $(LOG_IMEM_P2); then echo "PASS"; \
	elif grep -q "STATUS: SOME TESTS FAILED" $(LOG_IMEM_P2); then echo "FAIL"; \
	else echo "ERROR"; fi
	@echo "  → Log: $(LOG_IMEM_P2)"

.PHONY: tb_imm_gen
tb_imm_gen: $(BIN_IMM_GEN) $(LOGS)
	@printf "[RUN]     %-55s " "result_tb_imm_gen"
	@$(VVP) $(BIN_IMM_GEN) > $(LOG_IMM_GEN) 2>&1; \
	if grep -q "STATUS: ALL TESTS PASSED" $(LOG_IMM_GEN); then echo "PASS"; \
	elif grep -q "STATUS: SOME TESTS FAILED" $(LOG_IMM_GEN); then echo "FAIL"; \
	else echo "ERROR"; fi
	@echo "  → Log: $(LOG_IMM_GEN)"

.PHONY: tb_pc_next_logic
tb_pc_next_logic: $(BIN_PC_NEXT) $(LOGS)
	@printf "[RUN]     %-55s " "result_tb_pc_next_logic"
	@$(VVP) $(BIN_PC_NEXT) > $(LOG_PC_NEXT) 2>&1; \
	if grep -q "STATUS: ALL TESTS PASSED" $(LOG_PC_NEXT); then echo "PASS"; \
	elif grep -q "STATUS: SOME TESTS FAILED" $(LOG_PC_NEXT); then echo "FAIL"; \
	else echo "ERROR"; fi
	@echo "  → Log: $(LOG_PC_NEXT)"

.PHONY: tb_pc_reg
tb_pc_reg: $(BIN_PC_REG) $(LOGS)
	@printf "[RUN]     %-55s " "result_tb_pc_reg"
	@$(VVP) $(BIN_PC_REG) > $(LOG_PC_REG) 2>&1; \
	if grep -q "STATUS: ALL TESTS PASSED" $(LOG_PC_REG); then echo "PASS"; \
	elif grep -q "STATUS: SOME TESTS FAILED" $(LOG_PC_REG); then echo "FAIL"; \
	else echo "ERROR"; fi
	@echo "  → Log: $(LOG_PC_REG)"

.PHONY: tb_regfile
tb_regfile: $(BIN_REGFILE) $(LOGS)
	@printf "[RUN]     %-55s " "result_tb_regfile"
	@$(VVP) $(BIN_REGFILE) > $(LOG_REGFILE) 2>&1; \
	if grep -q "STATUS: ALL TESTS PASSED" $(LOG_REGFILE); then echo "PASS"; \
	elif grep -q "STATUS: SOME TESTS FAILED" $(LOG_REGFILE); then echo "FAIL"; \
	else echo "ERROR"; fi
	@echo "  → Log: $(LOG_REGFILE)"

.PHONY: tb_wb_mux
tb_wb_mux: $(BIN_WB_MUX) $(LOGS)
	@printf "[RUN]     %-55s " "result_tb_wb_mux"
	@$(VVP) $(BIN_WB_MUX) > $(LOG_WB_MUX) 2>&1; \
	if grep -q "STATUS: ALL TESTS PASSED" $(LOG_WB_MUX); then echo "PASS"; \
	elif grep -q "STATUS: SOME TESTS FAILED" $(LOG_WB_MUX); then echo "FAIL"; \
	else echo "ERROR"; fi
	@echo "  → Log: $(LOG_WB_MUX)"

.PHONY: tb_riscv32_singlecycle_top_program_1
tb_riscv32_singlecycle_top_program_1: $(BIN_TOP_P1) $(LOGS)
	@printf "[RUN]     %-55s " "result_tb_top_program_1"
	@$(VVP) $(BIN_TOP_P1) > $(LOG_TOP_P1) 2>&1; \
	if grep -q "STATUS: ALL TESTS PASSED" $(LOG_TOP_P1); then echo "PASS"; \
	elif grep -q "STATUS: SOME TESTS FAILED" $(LOG_TOP_P1); then echo "FAIL"; \
	else echo "ERROR"; fi
	@echo "  → Log: $(LOG_TOP_P1)"

.PHONY: tb_riscv32_singlecycle_top_program_2
tb_riscv32_singlecycle_top_program_2: $(BIN_TOP_P2) $(LOGS)
	@printf "[RUN]     %-55s " "result_tb_top_program_2"
	@$(VVP) $(BIN_TOP_P2) > $(LOG_TOP_P2) 2>&1; \
	if grep -q "STATUS: ALL TESTS PASSED" $(LOG_TOP_P2); then echo "PASS"; \
	elif grep -q "STATUS: SOME TESTS FAILED" $(LOG_TOP_P2); then echo "FAIL"; \
	else echo "ERROR"; fi
	@echo "  → Log: $(LOG_TOP_P2)"

#=====================================================================
# summary — print pass/fail table from log files
#=====================================================================
.PHONY: summary
summary:
	@echo ""
	@echo "======================================================"
	@echo " RV32I VERIFICATION REGRESSION SUMMARY"
	@echo "======================================================"
	@printf "  %-52s %s\n" "Testbench" "Result"
	@echo "  ----------------------------------------------------"
	@total=0; passed=0; failed=0; errors=0; \
	for pair in \
		"tb_alu:$(LOG_ALU)" \
		"tb_alu_control:$(LOG_ALU_CTRL)" \
		"tb_branch_unit:$(LOG_BRANCH)" \
		"tb_decoder_controller:$(LOG_DECODER)" \
		"tb_dmem:$(LOG_DMEM)" \
		"tb_imem_program_1:$(LOG_IMEM_P1)" \
		"tb_imem_program_2:$(LOG_IMEM_P2)" \
		"tb_imm_gen:$(LOG_IMM_GEN)" \
		"tb_pc_next_logic:$(LOG_PC_NEXT)" \
		"tb_pc_reg:$(LOG_PC_REG)" \
		"tb_regfile:$(LOG_REGFILE)" \
		"tb_wb_mux:$(LOG_WB_MUX)" \
		"tb_riscv32_singlecycle_top_program_1:$(LOG_TOP_P1)" \
		"tb_riscv32_singlecycle_top_program_2:$(LOG_TOP_P2)"; \
	do \
		name=$${pair%%:*}; log=$${pair##*:}; \
		total=$$((total + 1)); \
		if [ ! -f "$$log" ]; then \
			printf "  %-52s %s\n" "$$name" "NOT RUN"; \
			errors=$$((errors + 1)); \
		elif grep -q "STATUS: ALL TESTS PASSED" "$$log"; then \
			tests=$$(grep -oP 'Total Tests\s+:\s+\K[0-9]+' "$$log" | tail -1); \
			printf "  %-52s PASS  [%s tests]\n" "$$name" "$${tests:-?}"; \
			passed=$$((passed + 1)); \
		elif grep -q "STATUS: SOME TESTS FAILED" "$$log"; then \
			fail_count=$$(grep -oP 'Failed\s+:\s+\K[0-9]+' "$$log" | tail -1); \
			tests=$$(grep -oP 'Total Tests\s+:\s+\K[0-9]+' "$$log" | tail -1); \
			printf "  %-52s FAIL  [%s/%s failed]\n" "$$name" "$${fail_count:-?}" "$${tests:-?}"; \
			failed=$$((failed + 1)); \
		else \
			printf "  %-52s ERROR (simulation did not complete)\n" "$$name"; \
			errors=$$((errors + 1)); \
		fi; \
	done; \
	echo "  ----------------------------------------------------"; \
	echo ""; \
	printf "  Total: %d  |  Passed: %d  |  Failed: %d  |  Errors: %d\n" \
		$$total $$passed $$failed $$errors; \
	echo ""; \
	if [ $$failed -eq 0 ] && [ $$errors -eq 0 ]; then \
		echo "  ✓ ALL TESTBENCHES PASSED"; \
	else \
		echo "  ✗ REGRESSION INCOMPLETE — review logs in $(LOGS)/"; \
	fi; \
	echo "======================================================"
	@echo ""

#=====================================================================
# clean — remove all generated files
#=====================================================================
.PHONY: clean
clean:
	@echo "[CLEAN]  Removing simulation binaries..."
	@rm -f $(ALL_BINS)
	@echo "[CLEAN]  Removing simulation logs..."
	@rm -f $(ALL_LOGS)
	@echo "[CLEAN]  Removing VCD waveforms..."
	@rm -f $(VCD)/tb_*.vcd
	@echo "[CLEAN]  Done."
