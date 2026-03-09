//=====================================================================
// File        : pc_next_logic.v
// Author      : Prabhat Pandey
// Created On  : 16-Feb-2026
// Project     : RV32I Single-Cycle 32-bit RISC-V Processor
// Module Name : pc_next_logic
// Description :
//   This module generates the next program counter (PC) value for an
//   RV32I single-cycle processor.
//
//   PC Update Sources (priority order):
//     1) JALR : pc_next = (rs1 + immI) & ~1
//     2) JAL  : pc_next = pc_current + immJ
//     3) BRANCH taken : pc_next = pc_current + immB
//     4) Default : pc_next = pc_current + 4
//
// Inputs:
//   - pc_current   : current PC
//   - rs1_val      : value of rs1 (needed for JALR target)
//   - imm_i        : I-type immediate (for JALR)
//   - imm_b        : B-type immediate (for branch target)
//   - imm_j        : J-type immediate (for JAL target)
//   - branch       : indicates instruction is a branch
//   - take_branch  : output from branch_unit (branch condition result)
//   - jump         : indicates JAL instruction
//   - jalr         : indicates JALR instruction
//
// Outputs:
//   - pc_next       : next PC
//   - pc_plus4      : pc_current + 4 (useful for writeback on jal/jalr)
//
// Notes:
//   - RISC-V spec requires JALR target to have bit0 = 0.
//     That is why we AND with 32'hFFFF_FFFE.
//   - This module does NOT check illegal combinations of control
//     signals. The controller must ensure only valid combinations.
//
// Revision History:
//   - 16-Feb-2026 : Initial version
//=====================================================================

module pc_next_logic (
    input  wire [31:0] pc_current,    // Current PC
    input  wire [31:0] rs1_val,       // rs1 value (for jalr)
    input  wire [31:0] imm_i,         // I-type immediate
    input  wire [31:0] imm_b,         // B-type immediate
    input  wire [31:0] imm_j,         // J-type immediate

    input  wire        branch,        // branch instruction
    input  wire        take_branch,   // branch condition result
    input  wire        jump,          // jal instruction
    input  wire        jalr,          // jalr instruction

    output reg  [31:0] pc_next,       // Next PC
    output wire [31:0] pc_plus4       // PC + 4
);

    //=================================================================
    // PC + 4 calculation
    //=================================================================
    assign pc_plus4 = pc_current + 32'd4;

    //=================================================================
    // Combinational PC next selection logic
    //=================================================================
    always @(*) begin

        // Default: sequential execution
        pc_next = pc_plus4;

        // Priority 1: JALR (highest priority)
        if (jalr) begin
            // Spec: clear bit0 of target address
            pc_next = (rs1_val + imm_i) & 32'hFFFF_FFFE;
        end

        // Priority 2: JAL
        else if (jump) begin
            pc_next = pc_current + imm_j;
        end

        // Priority 3: Branch taken
        else if (branch && take_branch) begin
            pc_next = pc_current + imm_b;
        end

        // Else: pc_next stays pc_plus4
    end

endmodule
