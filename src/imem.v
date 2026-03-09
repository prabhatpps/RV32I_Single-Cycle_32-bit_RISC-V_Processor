//=====================================================================
// File        : imem.v
// Author      : Prabhat Pandey
// Created On  : 14-Feb-2026
// Project     : RV32I Single-Cycle 32-bit RISC-V Processor
// Module Name : imem
// Description :
//   This module implements Instruction Memory (IMEM) for an RV32
//   single-cycle RISC-V processor.
//
//   The instruction memory is modeled as a ROM-like array.
//   Initialization is expected to be done at the top level or testbench
//   (simulation-only), not inside this module.
//
//   Key Points:
//   - Instructions are 32-bit wide (one word)
//   - RISC-V instructions are always 4-byte aligned
//   - Therefore, the memory is indexed using addr[31:2] (word address)
//
// Behavior:
//   - Combinational read: instr updates immediately with addr changes
//   - No write port (ROM behavior for instruction memory)
//
// Notes:
//   - This is perfect for simulation and FPGA-style ROM.
//   - For ASIC, IMEM would be replaced by a real ROM or instruction cache.
//
// Revision History:
//   - 25-Feb-2026 : updated to make it synthesis-friendly
//   - 14-Feb-2026 : Initial version
//=====================================================================

module imem #(
    parameter MEM_DEPTH_WORDS = 1024                   // Total words in IMEM
)(
`ifdef USE_SRAM_MACROS
    input  wire        clk,                            // Needed only for SRAM macro mode
`endif
    input  wire [31:0] addr,                           // Byte address from PC
    output wire [31:0] instr                           // 32-bit instruction output
);

`ifdef USE_SRAM_MACROS
`ifdef SYNTHESIS
    //=================================================================
    // SRAM Macro Mapping (Synthesis/OpenLane path)
    //=================================================================
    // Tech_libs indicates a readily available 1KB OpenRAM macro:
    //   sky130_sram_1kbyte_1rw1r_32x256_8
    //
    // In macro mode we map IMEM to 256 x 32 words.
    // Keep MEM_DEPTH_WORDS at 256 for ASIC macro flow.
    //=================================================================
`ifdef USE_POWER_PINS
    supply1 macro_vccd1;
    supply0 macro_vssd1;
`endif
    wire [31:0] instr_sram;

    sky130_sram_1kbyte_1rw1r_32x256_8 u_sram (
`ifdef USE_POWER_PINS
        .vccd1  (macro_vccd1),
        .vssd1  (macro_vssd1),
`endif
        .clk0   (clk),
        .csb0   (1'b1),
        .web0   (1'b1),
        .wmask0 (4'b0000),
        .addr0  (8'h00),
        .din0   (32'h0000_0000),
        .dout0  (),
        .clk1   (clk),
        .csb1   (1'b0),
        .addr1  (addr[9:2]),
        .dout1  (instr_sram)
    );

    assign instr = instr_sram;
`else
    //=================================================================
    // Behavioral Memory Model (Simulation/RTL verification path)
    //=================================================================
    reg [31:0] mem [0:MEM_DEPTH_WORDS-1];
    wire [$clog2(MEM_DEPTH_WORDS)-1:0] word_index;
    assign word_index = addr[31:2];
    assign instr = mem[word_index];
`endif
`else
    //=================================================================
    // Behavioral Memory Model (Simulation/RTL verification path)
    //=================================================================
    reg [31:0] mem [0:MEM_DEPTH_WORDS-1];
    wire [$clog2(MEM_DEPTH_WORDS)-1:0] word_index;
    assign word_index = addr[31:2];
    assign instr = mem[word_index];
`endif

endmodule
