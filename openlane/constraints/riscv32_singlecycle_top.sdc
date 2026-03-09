# SDC constraints for RV32I single-cycle top in Sky130/OpenLane

# Primary clock
create_clock -name clk -period 20.000 [get_ports clk]
set_clock_uncertainty 0.20 [get_clocks clk]
set_clock_transition 0.10 [get_clocks clk]

# Constrain reset as a non-timing-critical control signal
set_false_path -from [get_ports rst_n]

# Reasonable drive/load assumptions for top-level ports
set_driving_cell -lib_cell sky130_fd_sc_hd__inv_8 [get_ports rst_n]
set_input_transition 0.10 [get_ports rst_n]
set_load 0.05 [all_outputs]
