//=====================================================================
// File        : wb_mux.v
// Author      : Prabhat Pandey
// Created On  : 16-Feb-2026
// Project     : RV32I Single-Cycle 32-bit RISC-V Processor
// Module Name : wb_mux
// Description :
//   This module implements the Writeback Multiplexer for an RV32I
//   single-cycle processor.
//
//   The writeback mux selects which value is written back into the
//   destination register (rd) of the register file.
//
// Inputs:
//   - wb_sel      : 3-bit writeback select (from controller)
//   - alu_result  : result from ALU (R-type, I-type, address calc)
//   - mem_data    : data loaded from data memory (lw)
//   - pc_plus4    : PC + 4 (jal/jalr link address)
//   - u_imm       : U-type immediate (lui) -> imm[31:12] << 12
//   - pc_plus_imm : PC + immediate (auipc)
//
// Output:
//   - wb_data     : final data written into regfile
//
// wb_sel Encoding:
//   000 : ALU result
//   001 : Memory read data
//   010 : PC + 4
//   011 : U-immediate (LUI)
//   100 : PC + immediate (AUIPC)
//   others : 0 (safe)
//
// Notes:
//   - This module is purely combinational.
//   - A safe default of 0 is used for unused wb_sel values.
//
// Revision History:
//   - 16-Feb-2026 : Initial version
//=====================================================================

module wb_mux (
    input  wire [2:0]  wb_sel,       // writeback select
    input  wire [31:0] alu_result,   // from ALU
    input  wire [31:0] mem_data,     // from DMEM (lw)
    input  wire [31:0] pc_plus4,     // PC + 4
    input  wire [31:0] u_imm,        // LUI immediate
    input  wire [31:0] pc_plus_imm,  // AUIPC result
    output reg  [31:0] wb_data       // final writeback data
);

    //=================================================================
    // Combinational Writeback Selection
    //=================================================================
    always @(*) begin
        case (wb_sel)

            3'b000: wb_data = alu_result;   // ALU result
            3'b001: wb_data = mem_data;     // Load data
            3'b010: wb_data = pc_plus4;     // Link address (JAL/JALR)
            3'b011: wb_data = u_imm;        // LUI
            3'b100: wb_data = pc_plus_imm;  // AUIPC

            default: wb_data = 32'h0000_0000; // safe

        endcase
    end

endmodule
