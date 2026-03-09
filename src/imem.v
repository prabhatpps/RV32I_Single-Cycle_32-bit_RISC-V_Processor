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
    input  wire [31:0] addr,                           // Byte address from PC
    output wire [31:0] instr                           // 32-bit instruction output
);

    //=================================================================
    // Instruction Memory Storage
    //=================================================================
    // Each entry is one 32-bit RISC-V instruction word.
    // MEM_DEPTH_WORDS = number of 32-bit words.
    //=================================================================
    reg [31:0] mem [0:MEM_DEPTH_WORDS-1];

    //=================================================================
    // Address Mapping (Word Addressing)
    //=================================================================
    // RISC-V instructions are 4-byte aligned.
    // So:
    //   PC = byte address
    //   Index = PC / 4 = PC[31:2]
    //=================================================================
    wire [$clog2(MEM_DEPTH_WORDS)-1:0] word_index;
    assign word_index = addr[31:2];

    //=================================================================
    // Combinational Read Output
    //=================================================================
    // Reads instruction directly from memory.
    // No clock required (ROM-like).
    //=================================================================
    assign instr = mem[word_index];

endmodule
