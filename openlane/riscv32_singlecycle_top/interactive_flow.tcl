# Run with:
#   cd /home/prabhat/OpenLane
#   ./flow.tcl -interactive -file /home/prabhat/Work_Fedora/RV32I_Single-Cycle_32-bit_RISC-V_Processor/openlane/riscv32_singlecycle_top/interactive_flow.tcl

package require openlane

set design_dir [file normalize [file dirname [info script]]]
prep -design $design_dir -tag rv32i_macro -overwrite

run_synthesis
run_floorplan
run_placement
run_cts
run_routing
run_parasitics_sta
run_magic
run_klayout
run_lvs
run_drc

puts "OpenLane flow completed for $::env(DESIGN_NAME)"
