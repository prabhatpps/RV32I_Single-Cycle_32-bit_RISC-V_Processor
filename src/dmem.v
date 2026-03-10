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

`ifdef USE_SRAM_MACROS
`ifdef SYNTHESIS
    //=================================================================
    // SRAM Macro Mapping (Synthesis/OpenLane path)
    //=================================================================
    // Map DMEM to one 256 x 32 OpenRAM macro.
    //=================================================================
`ifdef USE_POWER_PINS
    supply1 macro_vccd1;
    supply0 macro_vssd1;
`endif
    wire [31:0] dout0_sram;
    wire        csb0_sram;
    wire        web0_sram;

    assign csb0_sram = ~(mem_read | mem_write); // active-low chip select
    assign web0_sram = ~mem_write;              // active-low write enable

    sky130_sram_1kbyte_1rw1r_32x256_8 u_sram (
`ifdef USE_POWER_PINS
        .vccd1  (macro_vccd1),
        .vssd1  (macro_vssd1),
`endif
        .clk0   (clk),
        .csb0   (csb0_sram),
        .web0   (web0_sram),
        .wmask0 (4'b1111),
        .addr0  (addr[9:2]),
        .din0   (write_data),
        .dout0  (dout0_sram),
        .clk1   (clk),
        .csb1   (1'b1),
        .addr1  (8'h00),
        .dout1  ()
    );

    always @(*) begin
        if (mem_read)
            read_data = dout0_sram;
        else
            read_data = 32'h0000_0000;
    end
`else
    //=================================================================
    // Behavioral Memory Model (Simulation/RTL verification path)
    //=================================================================
    reg [31:0] mem [0:DEPTH-1];
    wire [31:0] word_index;
    assign word_index = addr >> 2;

    always @(*) begin
        if (mem_read)
            read_data = mem[word_index];
        else
            read_data = 32'h0000_0000;
    end

    always @(posedge clk) begin
        if (mem_write)
            mem[word_index] <= write_data;
    end
`endif
`else
    //=================================================================
    // Behavioral Memory Model (Simulation/RTL verification path)
    //=================================================================
    reg [31:0] mem [0:DEPTH-1];
    wire [31:0] word_index;
    assign word_index = addr >> 2;

    always @(*) begin
        if (mem_read)
            read_data = mem[word_index];
        else
            read_data = 32'h0000_0000;
    end

    always @(posedge clk) begin
        if (mem_write)
            mem[word_index] <= write_data;
    end
`endif

endmodule
