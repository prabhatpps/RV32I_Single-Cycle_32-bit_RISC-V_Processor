# SDC (Synopsys Design Constraints) for the RV32I single-cycle top module.
# This file tells STA/synthesis/PnR tools how to model timing for clocks,
# asynchronous controls, and external I/O electrical assumptions.

# Create the primary top-level clock named "clk" from input port "clk".
# -period 20.000 means a 20 ns clock period, i.e., 50 MHz frequency.
create_clock -name clk -period 20.000 [get_ports clk]

# Add clock uncertainty (0.20 ns) to model combined clock jitter/skew margin.
# Tools subtract this margin from available setup time (and use it for hold checks).
set_clock_uncertainty 0.20 [get_clocks clk]

# Define expected input clock edge transition (slew) as 0.10 ns.
# This helps timing engines estimate cell delay more realistically.
set_clock_transition 0.10 [get_clocks clk]

# Mark all paths starting from asynchronous reset port "rst_n" as false paths.
# This prevents tools from trying to close synchronous timing on reset assertion/
# deassertion paths, which are typically not timed like regular data paths.
set_false_path -from [get_ports rst_n]

# Model reset input drive strength using a specific Sky130 standard cell.
# This approximates the external source that drives rst_n during timing analysis.
set_driving_cell -lib_cell sky130_fd_sc_hd__inv_8 [get_ports rst_n]

# Set input transition (slew) on rst_n to 0.10 ns for delay/slew calculations.
set_input_transition 0.10 [get_ports rst_n]

# Apply a generic output capacitive load of 0.05 (library capacitance units)
# on all top-level outputs to model downstream fanout/environment loading.
set_load 0.05 [all_outputs]
