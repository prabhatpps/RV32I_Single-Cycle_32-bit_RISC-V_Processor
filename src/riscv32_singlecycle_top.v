//=====================================================================
// File        : riscv32_singlecycle_top.v
// Author      : Prabhat Pandey
// Created On  : 16-Feb-2026
// Project     : RV32I Single-Cycle 32-bit RISC-V Processor
// Module Name : riscv32_singlecycle_top
// Description :
//   Top-level integration module for an RV32I Single-Cycle 32-bit
//   RISC-V processor.
//
//   This module connects the complete datapath and control blocks:
//
//     - pc_reg               : holds current PC
//     - imem                 : instruction memory
//     - decoder_controller   : generates control signals
//     - regfile              : 32x32 register file (with rst_n)
//     - imm_gen              : immediate generator (I/S/B/U/J)
//     - alu_control          : ALU control decoder
//     - alu                  : executes arithmetic/logic ops
//     - branch_unit          : evaluates branch conditions
//     - dmem                 : data memory (lw/sw)
//     - wb_mux               : selects writeback data
//     - pc_next_logic        : selects next PC value
//
// Notes:
//   - This is a single-cycle CPU: fetch, decode, execute, mem, wb
//     all happen in one clock cycle.
//   - Reset initializes PC to 0 and clears regfile.
//   - Instruction memory and data memory are behavioral models.
//   - Memory initialization is expected in the testbench (simulation-only).
//   - No pipeline, no hazards, no stalls.
//
// Revision History:
//   - 25-Feb-2026 : updated to make it synthesis-friendly
//   - 16-Feb-2026 : Corrected regfile + imm_gen port integration
//   - 16-Feb-2026 : Initial version
//=====================================================================

module riscv32_singlecycle_top #(
    parameter IMEM_DEPTH_WORDS = 4096,
    parameter DMEM_DEPTH_WORDS = 256
)(
    input  wire clk,
    input  wire rst_n
);

    //=============================================================
    // 1) Program Counter (PC)
    //=============================================================
    wire [31:0] pc_current;
    wire [31:0] pc_next;

    pc_reg u_pc_reg (
        .clk        (clk),
        .rst_n      (rst_n),
        .pc_next    (pc_next),
        .pc_current (pc_current)
    );

    //=============================================================
    // 2) Instruction Fetch (IMEM)
    //=============================================================
    wire [31:0] instr;

    imem #(
        .MEM_DEPTH_WORDS(IMEM_DEPTH_WORDS)
    ) u_imem (
        .addr  (pc_current),
        .instr (instr)
    );

    //=============================================================
    // 3) Extract instruction fields
    //=============================================================
    wire [6:0] opcode;
    wire [4:0] rd;
    wire [2:0] funct3;
    wire [4:0] rs1;
    wire [4:0] rs2;
    wire [6:0] funct7;

    assign opcode = instr[6:0];
    assign rd     = instr[11:7];
    assign funct3 = instr[14:12];
    assign rs1    = instr[19:15];
    assign rs2    = instr[24:20];
    assign funct7 = instr[31:25];

    //=============================================================
    // 4) Controller (Main Decoder)
    //=============================================================
    wire        reg_write;
    wire [2:0]  wb_sel;

    wire        alu_src;
    wire [1:0]  alu_op;
    wire        use_pc_as_alu_a;

    wire        mem_read;
    wire        mem_write;

    wire        branch;
    wire        jump;
    wire        jalr;

    decoder_controller u_decoder_controller (
        .opcode           (opcode),
        .funct3           (funct3),
        .funct7           (funct7),

        .reg_write        (reg_write),
        .wb_sel           (wb_sel),

        .alu_src          (alu_src),
        .alu_op           (alu_op),
        .use_pc_as_alu_a  (use_pc_as_alu_a),

        .mem_read         (mem_read),
        .mem_write        (mem_write),

        .branch           (branch),
        .jump             (jump),
        .jalr             (jalr)
    );

    //=============================================================
    // 5) Register File (with reset)
    //=============================================================
    wire [31:0] rs1_val;
    wire [31:0] rs2_val;
    wire [31:0] wb_data;

    regfile u_regfile (
        .clk   (clk),
        .rst_n (rst_n),
        .we    (reg_write),
        .rs1   (rs1),
        .rs2   (rs2),
        .rd    (rd),
        .wd    (wb_data),
        .rd1   (rs1_val),
        .rd2   (rs2_val)
    );

    //=============================================================
    // 6) Immediate Generator (I/S/B/U/J)
    //=============================================================
    wire [31:0] imm_i;
    wire [31:0] imm_s;
    wire [31:0] imm_b;
    wire [31:0] imm_u;
    wire [31:0] imm_j;

    imm_gen u_imm_gen (
        .instr (instr),
        .imm_i (imm_i),
        .imm_s (imm_s),
        .imm_b (imm_b),
        .imm_u (imm_u),
        .imm_j (imm_j)
    );

    //=============================================================
    // 7) ALU Control
    //=============================================================
    wire [3:0] alu_ctrl;

    alu_control u_alu_control (
        .alu_op   (alu_op),
        .funct3   (funct3),
        .funct7   (funct7),
        .alu_ctrl (alu_ctrl)
    );

    //=============================================================
    // 8) ALU Operand Selection
    //=============================================================
    wire [31:0] alu_in_a;
    wire [31:0] alu_in_b;

    // ALU A selection:
    //   - Normally rs1
    //   - For AUIPC, use PC
    assign alu_in_a = (use_pc_as_alu_a) ? pc_current : rs1_val;

    // ALU B selection:
    //   - Normally rs2
    //   - For immediate-based ops, use immediate
    //
    // IMPORTANT:
    //   STORE uses imm_s, not imm_i
    //
    wire [31:0] selected_imm;

    assign selected_imm =
        (opcode == 7'b0100011) ? imm_s : // STORE
                                imm_i;  // LOAD, OP-IMM, JALR

    assign alu_in_b = (alu_src) ? selected_imm : rs2_val;

    //=============================================================
    // 9) ALU Execution
    //=============================================================
    wire [31:0] alu_result;
    wire        alu_zero;
    wire        alu_negative;
    wire        alu_carry;
    wire        alu_overflow;

    alu u_alu (
        .A          (alu_in_a),
        .B          (alu_in_b),
        .ALUControl (alu_ctrl),
        .Result     (alu_result),
        .Carry      (alu_carry),
        .OverFlow   (alu_overflow),
        .Zero       (alu_zero),
        .Negative   (alu_negative)
    );

    //=============================================================
    // 10) Branch Unit (Condition Evaluation)
    //=============================================================
    wire take_branch;

    branch_unit u_branch_unit (
        .funct3      (funct3),
        .rs1_val     (rs1_val),
        .rs2_val     (rs2_val),
        .take_branch (take_branch)
    );

    //=============================================================
    // 11) Data Memory (DMEM)
    //=============================================================
    wire [31:0] mem_data;

    dmem #(
        .DEPTH(DMEM_DEPTH_WORDS)
    ) u_dmem (
        .clk        (clk),
        .mem_read   (mem_read),
        .mem_write  (mem_write),
        .addr       (alu_result),
        .write_data (rs2_val),
        .read_data  (mem_data)
    );

    //=============================================================
    // 12) PC Next Logic
    //=============================================================
    wire [31:0] pc_plus4;

    pc_next_logic u_pc_next_logic (
        .pc_current  (pc_current),
        .rs1_val     (rs1_val),
        .imm_i       (imm_i),
        .imm_b       (imm_b),
        .imm_j       (imm_j),
        .branch      (branch),
        .take_branch (take_branch),
        .jump        (jump),
        .jalr        (jalr),
        .pc_next     (pc_next),
        .pc_plus4    (pc_plus4)
    );

    //=============================================================
    // 13) Writeback Mux
    //=============================================================
    // AUIPC requires PC + imm_u
    wire [31:0] pc_plus_imm_u;
    assign pc_plus_imm_u = pc_current + imm_u;

    wb_mux u_wb_mux (
        .wb_sel      (wb_sel),
        .alu_result  (alu_result),
        .mem_data    (mem_data),
        .pc_plus4    (pc_plus4),
        .u_imm       (imm_u),
        .pc_plus_imm (pc_plus_imm_u),
        .wb_data     (wb_data)
    );

endmodule
