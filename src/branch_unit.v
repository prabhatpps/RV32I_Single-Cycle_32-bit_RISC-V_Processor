//=====================================================================
// File        : branch_unit.v
// Author      : Prabhat Pandey
// Created On  : 16-Feb-2026
// Project     : RV32I Single-Cycle 32-bit RISC-V Processor
// Module Name : branch_unit
// Description :
//   This module implements the branch decision logic for RV32I.
//
//   It evaluates the branch condition based on:
//     - funct3 field (branch type)
//     - rs1 and rs2 register values
//
// Supported RV32I Branch Instructions (funct3):
//   000 : BEQ   (branch if equal)
//   001 : BNE   (branch if not equal)
//   100 : BLT   (branch if rs1 < rs2, signed)
//   101 : BGE   (branch if rs1 >= rs2, signed)
//   110 : BLTU  (branch if rs1 < rs2, unsigned)
//   111 : BGEU  (branch if rs1 >= rs2, unsigned)
//
// Inputs:
//   - funct3   : instruction funct3 field
//   - rs1_val  : 32-bit value from register rs1
//   - rs2_val  : 32-bit value from register rs2
//
// Output:
//   - take_branch : 1 if branch condition is true, else 0
//
// Notes:
//   - This module only decides the condition.
//   - PC target calculation (PC + immB) is handled separately in
//     pc_next_logic.
//
// Revision History:
//   - 16-Feb-2026 : Initial version
//=====================================================================

module branch_unit (
    input  wire [2:0]  funct3,        // Branch funct3
    input  wire [31:0] rs1_val,        // rs1 register value
    input  wire [31:0] rs2_val,        // rs2 register value
    output reg         take_branch     // Branch decision output
);

    //=================================================================
    // Internal comparison signals
    //=================================================================
    wire eq;
    wire lt_signed;
    wire lt_unsigned;

    assign eq          = (rs1_val == rs2_val);
    assign lt_signed   = ($signed(rs1_val) < $signed(rs2_val));
    assign lt_unsigned = (rs1_val < rs2_val);

    //=================================================================
    // Branch decision logic (combinational)
    //=================================================================
    always @(*) begin
        take_branch = 1'b0;

        case (funct3)

            3'b000: begin
                // BEQ
                take_branch = eq;
            end

            3'b001: begin
                // BNE
                take_branch = ~eq;
            end

            3'b100: begin
                // BLT (signed)
                take_branch = lt_signed;
            end

            3'b101: begin
                // BGE (signed) => !(rs1 < rs2)
                take_branch = ~lt_signed;
            end

            3'b110: begin
                // BLTU (unsigned)
                take_branch = lt_unsigned;
            end

            3'b111: begin
                // BGEU (unsigned) => !(rs1 < rs2)
                take_branch = ~lt_unsigned;
            end

            default: begin
                // Not a valid branch funct3
                take_branch = 1'b0;
            end

        endcase
    end

endmodule
