# Custom netgen setup for macro-heavy LVS.
# Source the default Sky130A setup, then ignore SRAM macro internals.

source /home/prabhat/.ciel/sky130A/libs.tech/netgen/sky130A_setup.tcl

set cells1 [cells list -all -circuit1]
set cells2 [cells list -all -circuit2]

foreach cell $cells1 {
    if {[regexp {^sky130_sram_} $cell]} {
        ignore class "-circuit1 $cell"
    }
}

foreach cell $cells2 {
    if {[regexp {^sky130_sram_} $cell]} {
        ignore class "-circuit2 $cell"
    }
}

