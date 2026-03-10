set ::env(DESIGN_NAME) riscv32_singlecycle_top
set ::env(PDK) sky130A
set ::env(STD_CELL_LIBRARY) sky130_fd_sc_hd
set ::env(VDD_PIN) VPWR
set ::env(GND_PIN) VGND
set ::env(VDD_NETS) [list VPWR]
set ::env(GND_NETS) [list VGND]

set ::env(VERILOG_FILES) [list \
    $::env(DESIGN_DIR)/../../src/riscv32_singlecycle_top.v \
    $::env(DESIGN_DIR)/../../src/pc_reg.v \
    $::env(DESIGN_DIR)/../../src/imem.v \
    $::env(DESIGN_DIR)/../../src/decoder_controller.v \
    $::env(DESIGN_DIR)/../../src/regfile.v \
    $::env(DESIGN_DIR)/../../src/imm_gen.v \
    $::env(DESIGN_DIR)/../../src/alu_control.v \
    $::env(DESIGN_DIR)/../../src/alu.v \
    $::env(DESIGN_DIR)/../../src/branch_unit.v \
    $::env(DESIGN_DIR)/../../src/dmem.v \
    $::env(DESIGN_DIR)/../../src/pc_next_logic.v \
    $::env(DESIGN_DIR)/../../src/wb_mux.v \
]

# Use SRAM-macro implementation path in imem/dmem/regfile
set ::env(SYNTH_DEFINES) [list USE_SRAM_MACROS]
set ::env(SYNTH_NO_FLAT) 1
set ::env(SYNTH_USE_PG_PINS_DEFINES) [list USE_POWER_PINS]

# Macro blackbox declaration for Yosys
set ::env(VERILOG_FILES_BLACKBOX) [list \
    $::env(DESIGN_DIR)/../../src/sky130_sram_1kbyte_1rw1r_32x256_8.bb.v \
]

# SRAM macro views from Sky130 PDK
set macro_root $::env(PDK_ROOT)/$::env(PDK)/libs.ref/sky130_sram_macros
set ::env(EXTRA_LEFS) [list \
    $macro_root/lef/sky130_sram_1kbyte_1rw1r_32x256_8.lef \
]
set ::env(EXTRA_GDS_FILES) [list \
    $macro_root/gds/sky130_sram_1kbyte_1rw1r_32x256_8.gds \
]
set ::env(EXTRA_LIBS) [list \
    $macro_root/lib/sky130_sram_1kbyte_1rw1r_32x256_8_TT_1p8V_25C.lib \
]
set ::env(LVS_EXTRA_STD_CELL_LIBRARY) [list \
    $macro_root/spice/sky130_sram_1kbyte_1rw1r_32x256_8.spice \
]
set ::env(NETGEN_SETUP_FILE) $::env(DESIGN_DIR)/sky130A_setup_macros.tcl
set ::env(MAGIC_EXT_USE_GDS) 1

# Timing constraints
set ::env(BASE_SDC_FILE) $::env(DESIGN_DIR)/../constraints/riscv32_singlecycle_top.sdc
set ::env(CLOCK_PORT) clk
set ::env(CLOCK_NET) clk
set ::env(CLOCK_PERIOD) 20.0

# Floorplan sized for 4 SRAM macros + logic
set ::env(FP_SIZING) absolute
set ::env(DIE_AREA) "0 0 1700 1700"
set ::env(CORE_AREA) "100 100 1600 1600"
set ::env(PL_TARGET_DENSITY) 0.15
set ::env(PL_MACRO_HALO) "20 20"
set ::env(PL_MACRO_CHANNEL) "80 80"
set ::env(MACRO_PLACEMENT_CFG) $::env(DESIGN_DIR)/macro_placement.cfg

# Connect macro PG pins to top-level PDN
set ::env(FP_PDN_MACRO_HOOKS) [list \
    u_imem.u_sram VPWR VGND vccd1 vssd1 \
    u_dmem.u_sram VPWR VGND vccd1 vssd1 \
    u_regfile.u_sram_rs1 VPWR VGND vccd1 vssd1 \
    u_regfile.u_sram_rs2 VPWR VGND vccd1 vssd1 \
]

# Conservative routing for macro-heavy floorplan
set ::env(GRT_ADJUSTMENT) 0.05
set ::env(GLB_RESIZER_DESIGN_OPTIMIZATIONS) 0
set ::env(GLB_RESIZER_TIMING_OPTIMIZATIONS) 0
set ::env(RUN_CVC) 0
