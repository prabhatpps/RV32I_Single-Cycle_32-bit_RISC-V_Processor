//=====================================================================
// File        : dmem.v
// Author      : Prabhat Pandey
// Created On  : 16-Feb-2026
// Project     : RV32I Single-Cycle 32-bit RISC-V Processor
// Module Name : dmem
// Description :
//   This module implements Data Memory (DMEM) for an RV32I single-cycle
//   processor.
//
//   Supported operations:
//     - LW : Load word (32-bit read)
//     - SW : Store word (32-bit write)
//
// Interface:
//   Inputs:
//     - clk       : clock (writes occur on posedge)
//     - mem_read  : when 1, read data is valid on read_data
//     - mem_write : when 1, write occurs on posedge clk
//     - addr      : 32-bit byte address (from ALU)
//     - write_data: 32-bit data to store (from rs2)
//
//   Outputs:
//     - read_data : 32-bit data loaded from memory
//
// Memory Organization:
//   - This DMEM is word-addressed internally.
//   - Since RV32I LW/SW operate on 32-bit aligned addresses,
//     we use addr[31:2] as the word index.
//   - addr[1:0] are ignored (assumed 00).
//
// Notes:
//   - Read is combinational for simplicity in single-cycle CPU.
//   - Write is synchronous on rising edge of clk.
//   - If mem_read=0, read_data returns 0.
//   - If mem_write=0, no memory update occurs.
//   - Memory initialization is expected to be done at the top level or
//     testbench (simulation-only), not inside this module.
//
// Revision History:
//   - 25-Feb-2026 : updated to make it synthesis-friendly
//   - 16-Feb-2026 : Initial version
//=====================================================================

module dmem #(
    parameter DEPTH = 256                // Number of 32-bit words
)(
    input  wire        clk,
    input  wire        mem_read,
    input  wire        mem_write,
    input  wire [31:0] addr,             // Byte address
    input  wire [31:0] write_data,       // Data to store
    output reg  [31:0] read_data         // Data loaded
);

    //=================================================================
    // Memory array (word-addressed)
    //=================================================================
    reg [31:0] mem [0:DEPTH-1];

    //=================================================================
    // Word index extraction
    //=================================================================
    // We assume aligned accesses, so addr[1:0] = 00.
    // Use addr[31:2] for word indexing.
    //=================================================================
    wire [31:0] word_index;
    assign word_index = addr >> 2;

    //=================================================================
    // Combinational read
    //=================================================================
    always @(*) begin
        if (mem_read)
            read_data = mem[word_index];
        else
            read_data = 32'h0000_0000;
    end

    //=================================================================
    // Synchronous write (posedge)
    //=================================================================
    always @(posedge clk) begin
        if (mem_write)
            mem[word_index] <= write_data;
    end

endmodule
