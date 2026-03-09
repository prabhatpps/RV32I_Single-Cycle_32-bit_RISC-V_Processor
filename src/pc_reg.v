//=====================================================================
// File        : pc_reg.v
// Author      : Prabhat Pandey
// Created On  : 12-Feb-2026
// Project     : RV32I Single-Cycle 32-bit RISC-V Processor
// Module Name : pc_reg
// Description :
//   This module implements the Program Counter (PC) register for a
//   single-cycle RV32 processor.
//
//   The PC holds the address of the instruction currently being fetched
//   from instruction memory.
//
//   On every rising edge of the clock:
//     - If reset is asserted (active-low), PC is cleared to 0x00000000.
//     - Otherwise, PC is updated with pc_next.
//
// Notes:
//   - RISC-V instructions are always 32-bit aligned, so PC should normally
//     be word-aligned (PC[1:0] = 2'b00).
//   - This module intentionally does NOT force alignment internally,
//     because alignment should be guaranteed by pc_next_logic.
//     (This avoids masking bugs during debugging.)
//
// Revision History:
//   - 25-Feb-2026 : updated to make synchronous reset
//   - 12-Feb-2026 : Initial version
//=====================================================================

module pc_reg (
    input  wire        clk,        // Clock input (positive-edge triggered)
    input  wire        rst_n,      // Active-low synchronous reset
    input  wire [31:0] pc_next,    // Next PC value computed by pc_next_logic
    output reg  [31:0] pc_current  // Current PC value used for instruction fetch
);

    //=================================================================
    // Sequential Logic: Program Counter Update
    //=================================================================
    // Triggering:
    //   - Updates on rising edge of clk
    //   - Resets on rising edge of clk when rst_n is low
    //
    // Reset Behavior:
    //   - PC is reset to 0x00000000
    //
    // Normal Operation:
    //   - PC loads pc_next every cycle
    //=================================================================
    always @(posedge clk) begin
        if (!rst_n) begin
            pc_current <= 32'h0000_0000;   // Reset PC to address 0
        end
        else begin
            pc_current <= pc_next;         // Update PC with computed next value
        end
    end

endmodule
