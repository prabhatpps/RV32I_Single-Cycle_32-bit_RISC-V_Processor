//=====================================================================
// File        : tb_decoder_controller.v
// Author      : Prabhat Pandey
// Created On  : 16-Feb-2026
// Project     : RV32I Single-Cycle 32-bit RISC-V Processor
// Testbench   : tb_decoder_controller
// Description :
//   Fully self-checking testbench for decoder_controller.v
//
//   This testbench verifies the control outputs for each RV32I opcode
//   group supported by the design.
//
// Supported opcode groups tested:
//   - OP       (R-type)
//   - OP-IMM   (I-type ALU)
//   - LOAD     (lw)
//   - STORE    (sw)
//   - BRANCH   (beq/bne/...)
//   - JAL
//   - JALR
//   - LUI
//   - AUIPC
//   - Default/unknown opcode
//
// Verification Features:
//   - Fully self-checking
//   - Input print
//   - Expected output print
//   - Actual output print
//   - PASS/FAIL per test case
//   - Global counters
//   - Final verification summary report
//
// Run Commands:
//   iverilog -o ./Verification_Results/result_tb_decoder_controller ./src/decoder_controller.v ./RTL_Verification/tb_decoder_controller.v
//   vvp ./Verification_Results/result_tb_decoder_controller
//=====================================================================

`timescale 1ns/1ps

module tb_decoder_controller;

    //=============================================================
    // Testbench Parameters
    //=============================================================
    localparam integer TEST_DELAY = 10; // ns between tests for waveform visibility

    //=============================================================
    // DUT Inputs
    //=============================================================
    reg  [6:0] opcode;
    reg  [2:0] funct3;
    reg  [6:0] funct7;

    //=============================================================
    // DUT Outputs
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

    //=============================================================
    // Instantiate DUT
    //=============================================================
    decoder_controller dut (
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
    // Global Counters
    //=============================================================
    integer total_tests;
    integer passed_tests;
    integer failed_tests;

    //=============================================================
    // VCD Dump (for GTKWave)
    //=============================================================
    initial begin
        $dumpfile("Verification_Results/vcd/tb_decoder_controller.vcd");
        $dumpvars(0, tb_decoder_controller);
    end

    //=============================================================
    // Task: Divider
    //=============================================================
    task print_divider;
        begin
            $display("----------------------------------------------------------------");
        end
    endtask

    //=============================================================
    // Task: Print Expected/Actual in aligned format
    //=============================================================
    task print_controls;
        input [8*12:1] tag;

        input exp_reg_write;
        input [2:0] exp_wb_sel;

        input exp_alu_src;
        input [1:0] exp_alu_op;
        input exp_use_pc_as_alu_a;

        input exp_mem_read;
        input exp_mem_write;

        input exp_branch;
        input exp_jump;
        input exp_jalr;

        begin
            $display("%s:", tag);
            $display("   reg_write       = %0d", exp_reg_write);
            $display("   wb_sel          = %03b", exp_wb_sel);
            $display("");
            $display("   alu_src         = %0d", exp_alu_src);
            $display("   alu_op          = %02b", exp_alu_op);
            $display("   use_pc_as_alu_a = %0d", exp_use_pc_as_alu_a);
            $display("");
            $display("   mem_read        = %0d", exp_mem_read);
            $display("   mem_write       = %0d", exp_mem_write);
            $display("");
            $display("   branch          = %0d", exp_branch);
            $display("   jump            = %0d", exp_jump);
            $display("   jalr            = %0d", exp_jalr);
        end
    endtask

    //=============================================================
    // Task: Run One Test
    //=============================================================
    task run_test;
        input [8*70:1] test_name;

        input [6:0] opcode_in;
        input [2:0] funct3_in;
        input [6:0] funct7_in;

        // Expected outputs
        input exp_reg_write;
        input [2:0] exp_wb_sel;

        input exp_alu_src;
        input [1:0] exp_alu_op;
        input exp_use_pc_as_alu_a;

        input exp_mem_read;
        input exp_mem_write;

        input exp_branch;
        input exp_jump;
        input exp_jalr;

        reg pass;
        begin
            total_tests = total_tests + 1;

            print_divider();
            $display("TEST : %s", test_name);

            // Apply inputs
            opcode = opcode_in;
            funct3 = funct3_in;
            funct7 = funct7_in;

            #2; // combinational settle

            // Print Inputs
            $display("Inputs:");
            $display("   opcode = %07b", opcode_in);
            $display("   funct3 = %03b", funct3_in);
            $display("   funct7 = %07b", funct7_in);

            $display("");

            // Print Expected
            print_controls("Expected",
                           exp_reg_write, exp_wb_sel,
                           exp_alu_src, exp_alu_op, exp_use_pc_as_alu_a,
                           exp_mem_read, exp_mem_write,
                           exp_branch, exp_jump, exp_jalr);

            $display("");

            // Print Actual
            print_controls("Got",
                           reg_write, wb_sel,
                           alu_src, alu_op, use_pc_as_alu_a,
                           mem_read, mem_write,
                           branch, jump, jalr);

            // Compare all signals
            pass = 1'b1;

            if (reg_write       !== exp_reg_write)       pass = 1'b0;
            if (wb_sel          !== exp_wb_sel)          pass = 1'b0;
            if (alu_src         !== exp_alu_src)         pass = 1'b0;
            if (alu_op          !== exp_alu_op)          pass = 1'b0;
            if (use_pc_as_alu_a !== exp_use_pc_as_alu_a) pass = 1'b0;
            if (mem_read        !== exp_mem_read)        pass = 1'b0;
            if (mem_write       !== exp_mem_write)       pass = 1'b0;
            if (branch          !== exp_branch)          pass = 1'b0;
            if (jump            !== exp_jump)            pass = 1'b0;
            if (jalr            !== exp_jalr)            pass = 1'b0;

            $display("");
            if (pass) begin
                passed_tests = passed_tests + 1;
                $display("STATUS: PASS");
            end
            else begin
                failed_tests = failed_tests + 1;
                $display("STATUS: FAIL");
            end

            print_divider();
            $display("");

            #(TEST_DELAY);
        end
    endtask

    //=============================================================
    // Main Test Sequence
    //=============================================================
    initial begin

        // Init counters
        total_tests  = 0;
        passed_tests = 0;
        failed_tests = 0;

        // Init inputs
        opcode = 7'b0000000;
        funct3 = 3'b000;
        funct7 = 7'b0000000;

        $display("====================================================");
        $display(" DECODER_CONTROLLER VERIFICATION STARTED — Author: Prabhat Pandey");
        $display("====================================================");
        $display("");

        //=========================================================
        // OP (R-type) : 0110011
        //=========================================================
        run_test("OP (R-type) control outputs",
                 7'b0110011, 3'b000, 7'b0000000,
                 1'b1, 3'b000,
                 1'b0, 2'b10, 1'b0,
                 1'b0, 1'b0,
                 1'b0, 1'b0, 1'b0);

        //=========================================================
        // OP-IMM : 0010011
        //=========================================================
        run_test("OP-IMM (I-type ALU) control outputs",
                 7'b0010011, 3'b000, 7'b0000000,
                 1'b1, 3'b000,
                 1'b1, 2'b11, 1'b0,
                 1'b0, 1'b0,
                 1'b0, 1'b0, 1'b0);

        //=========================================================
        // LOAD : 0000011
        //=========================================================
        run_test("LOAD (lw) control outputs",
                 7'b0000011, 3'b010, 7'b0000000,
                 1'b1, 3'b001,
                 1'b1, 2'b00, 1'b0,
                 1'b1, 1'b0,
                 1'b0, 1'b0, 1'b0);

        //=========================================================
        // STORE : 0100011
        //=========================================================
        run_test("STORE (sw) control outputs",
                 7'b0100011, 3'b010, 7'b0000000,
                 1'b0, 3'b000,
                 1'b1, 2'b00, 1'b0,
                 1'b0, 1'b1,
                 1'b0, 1'b0, 1'b0);

        //=========================================================
        // BRANCH : 1100011
        //=========================================================
        run_test("BRANCH control outputs",
                 7'b1100011, 3'b000, 7'b0000000,
                 1'b0, 3'b000,
                 1'b0, 2'b01, 1'b0,
                 1'b0, 1'b0,
                 1'b1, 1'b0, 1'b0);

        //=========================================================
        // JAL : 1101111
        //=========================================================
        run_test("JAL control outputs",
                 7'b1101111, 3'b000, 7'b0000000,
                 1'b1, 3'b010,
                 1'b0, 2'b00, 1'b0,
                 1'b0, 1'b0,
                 1'b0, 1'b1, 1'b0);

        //=========================================================
        // JALR : 1100111
        //=========================================================
        run_test("JALR control outputs",
                 7'b1100111, 3'b000, 7'b0000000,
                 1'b1, 3'b010,
                 1'b1, 2'b00, 1'b0,
                 1'b0, 1'b0,
                 1'b0, 1'b0, 1'b1);

        //=========================================================
        // LUI : 0110111
        //=========================================================
        run_test("LUI control outputs",
                 7'b0110111, 3'b000, 7'b0000000,
                 1'b1, 3'b011,
                 1'b0, 2'b00, 1'b0,
                 1'b0, 1'b0,
                 1'b0, 1'b0, 1'b0);

        //=========================================================
        // AUIPC : 0010111
        //=========================================================
        run_test("AUIPC control outputs",
                 7'b0010111, 3'b000, 7'b0000000,
                 1'b1, 3'b100,
                 1'b1, 2'b00, 1'b1,
                 1'b0, 1'b0,
                 1'b0, 1'b0, 1'b0);

        //=========================================================
        // Unknown opcode -> default safe
        //=========================================================
        run_test("Unknown opcode -> safe defaults (NOP-like)",
                 7'b1111111, 3'b111, 7'b1111111,
                 1'b0, 3'b000,
                 1'b0, 2'b00, 1'b0,
                 1'b0, 1'b0,
                 1'b0, 1'b0, 1'b0);

        //=========================================================
        // Final Summary Report
        //=========================================================
        $display("====================================================");
        $display(" DECODER_CONTROLLER VERIFICATION REPORT");
        $display("====================================================");
        $display("   Total Tests   : %0d", total_tests);
        $display("   Passed        : %0d", passed_tests);
        $display("   Failed        : %0d", failed_tests);
        $display("====================================================");

        if (failed_tests == 0) begin
            $display("STATUS: ALL TESTS PASSED");
        end
        else begin
            $display("STATUS: SOME TESTS FAILED");
        end

        $display("====================================================");
        $display("");

        $finish;
    end

endmodule
