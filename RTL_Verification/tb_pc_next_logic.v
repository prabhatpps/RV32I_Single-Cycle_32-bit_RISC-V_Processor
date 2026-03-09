//=====================================================================
// File        : tb_pc_next_logic.v
// Author      : Prabhat Pandey
// Created On  : 16-Feb-2026
// Project     : RV32I Single-Cycle 32-bit RISC-V Processor
// Testbench   : tb_pc_next_logic
// Description :
//   Fully self-checking testbench for pc_next_logic.v
//
// PC Update Priority (must match DUT):
//   1) JALR : pc_next = (rs1 + imm_i) & ~1
//   2) JAL  : pc_next = pc_current + imm_j
//   3) BRANCH taken : pc_next = pc_current + imm_b
//   4) Default : pc_next = pc_current + 4
//
// Verification Features:
//   - Fully self-checking
//   - Input print per test
//   - Expected output print
//   - Actual output print
//   - PASS/FAIL per test
//   - Global counters
//   - Final verification summary report
//
// Run Commands:
//   iverilog -o ./Verification_Results/result_tb_pc_next_logic ./src/pc_next_logic.v ./RTL_Verification/tb_pc_next_logic.v
//   vvp ./Verification_Results/result_tb_pc_next_logic
//=====================================================================

`timescale 1ns/1ps

module tb_pc_next_logic;

    //=============================================================
    // Testbench Parameters
    //=============================================================
    localparam integer TEST_DELAY = 10; // ns between tests for waveform visibility

    //=============================================================
    // DUT Inputs
    //=============================================================
    reg  [31:0] pc_current;
    reg  [31:0] rs1_val;
    reg  [31:0] imm_i;
    reg  [31:0] imm_b;
    reg  [31:0] imm_j;

    reg         branch;
    reg         take_branch;
    reg         jump;
    reg         jalr;

    //=============================================================
    // DUT Outputs
    //=============================================================
    wire [31:0] pc_next;
    wire [31:0] pc_plus4;

    //=============================================================
    // Instantiate DUT
    //=============================================================
    pc_next_logic dut (
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
    // Global Counters
    //=============================================================
    integer total_tests;
    integer passed_tests;
    integer failed_tests;

    //=============================================================
    // VCD Dump (for GTKWave)
    //=============================================================
    initial begin
        $dumpfile("Verification_Results/vcd/tb_pc_next_logic.vcd");
        $dumpvars(0, tb_pc_next_logic);
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
    // Task: Run One Test
    //=============================================================
    task run_test;
        input [8*70:1] test_name;

        input [31:0] pc_in;
        input [31:0] rs1_in;
        input [31:0] imm_i_in;
        input [31:0] imm_b_in;
        input [31:0] imm_j_in;

        input        branch_in;
        input        take_branch_in;
        input        jump_in;
        input        jalr_in;

        input [31:0] expected_pc_next;
        input [31:0] expected_pc_plus4;

        reg [31:0] got_pc_next;
        reg [31:0] got_pc_plus4;

        begin
            total_tests = total_tests + 1;

            print_divider();
            $display("TEST : %s", test_name);

            // Apply inputs
            pc_current  = pc_in;
            rs1_val     = rs1_in;
            imm_i       = imm_i_in;
            imm_b       = imm_b_in;
            imm_j       = imm_j_in;

            branch      = branch_in;
            take_branch = take_branch_in;
            jump        = jump_in;
            jalr        = jalr_in;

            #2; // settle combinational logic

            got_pc_next  = pc_next;
            got_pc_plus4 = pc_plus4;

            // Print Inputs
            $display("Inputs:");
            $display("   pc_current   = %08h", pc_in);
            $display("   rs1_val      = %08h", rs1_in);
            $display("   imm_i        = %08h", imm_i_in);
            $display("   imm_b        = %08h", imm_b_in);
            $display("   imm_j        = %08h", imm_j_in);
            $display("");
            $display("   branch       = %0d", branch_in);
            $display("   take_branch  = %0d", take_branch_in);
            $display("   jump         = %0d", jump_in);
            $display("   jalr         = %0d", jalr_in);

            // Print Expected
            $display("");
            $display("Expected:");
            $display("   pc_plus4     = %08h", expected_pc_plus4);
            $display("   pc_next      = %08h", expected_pc_next);

            // Print Got
            $display("");
            $display("Got:");
            $display("   pc_plus4     = %08h", got_pc_plus4);
            $display("   pc_next      = %08h", got_pc_next);

            // Compare
            if ((got_pc_next === expected_pc_next) &&
                (got_pc_plus4 === expected_pc_plus4)) begin
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

        // Init signals
        pc_current   = 32'h0000_0000;
        rs1_val      = 32'h0000_0000;
        imm_i        = 32'h0000_0000;
        imm_b        = 32'h0000_0000;
        imm_j        = 32'h0000_0000;
        branch       = 1'b0;
        take_branch  = 1'b0;
        jump         = 1'b0;
        jalr         = 1'b0;

        $display("====================================================");
        $display(" PC_NEXT_LOGIC VERIFICATION STARTED — Author: Prabhat Pandey");
        $display("====================================================");
        $display("");

        //=========================================================
        // TEST 1: Default PC+4
        //=========================================================
        run_test("Default: no branch/jump -> PC+4",
                 32'h0000_0100,
                 32'h0000_0000,
                 32'h0000_0000,
                 32'h0000_0010,
                 32'h0000_0020,
                 1'b0, 1'b0, 1'b0, 1'b0,
                 32'h0000_0104,
                 32'h0000_0104);

        //=========================================================
        // TEST 2: Branch not taken -> PC+4
        //=========================================================
        run_test("Branch not taken -> PC+4",
                 32'h0000_0200,
                 32'h0000_0000,
                 32'h0000_0000,
                 32'h0000_0010,  // imm_b
                 32'h0000_0000,
                 1'b1, 1'b0, 1'b0, 1'b0,
                 32'h0000_0204,
                 32'h0000_0204);

        //=========================================================
        // TEST 3: Branch taken -> PC + imm_b
        //=========================================================
        run_test("Branch taken -> PC + imm_b",
                 32'h0000_0200,
                 32'h0000_0000,
                 32'h0000_0000,
                 32'h0000_0010,  // +16
                 32'h0000_0000,
                 1'b1, 1'b1, 1'b0, 1'b0,
                 32'h0000_0210,
                 32'h0000_0204);

        //=========================================================
        // TEST 4: JAL -> PC + imm_j
        //=========================================================
        run_test("JAL -> PC + imm_j",
                 32'h0000_0300,
                 32'h0000_0000,
                 32'h0000_0000,
                 32'h0000_0040,
                 32'h0000_0020,  // +32
                 1'b0, 1'b0, 1'b1, 1'b0,
                 32'h0000_0320,
                 32'h0000_0304);

        //=========================================================
        // TEST 5: JALR -> (rs1 + imm_i) & ~1 (bit0 cleared)
        //=========================================================
        // rs1=0x1003, imm_i=0x00000004 => target=0x1007
        // bit0 cleared => 0x1006
        run_test("JALR -> (rs1+imm_i)&~1 (bit0 cleared)",
                 32'h0000_0000,
                 32'h0000_1003,
                 32'h0000_0004,
                 32'h0000_0000,
                 32'h0000_0000,
                 1'b0, 1'b0, 1'b0, 1'b1,
                 32'h0000_1006,
                 32'h0000_0004);

        //=========================================================
        // TEST 6: Priority check: JALR overrides JAL
        //=========================================================
        run_test("Priority: JALR overrides JAL",
                 32'h0000_0400,
                 32'h0000_2000,
                 32'h0000_0008,  // rs1+imm_i = 0x2008 -> already aligned
                 32'h0000_0100,
                 32'h0000_0200,
                 1'b0, 1'b0, 1'b1, 1'b1,
                 32'h0000_2008,
                 32'h0000_0404);

        //=========================================================
        // TEST 7: Priority check: JAL overrides Branch
        //=========================================================
        run_test("Priority: JAL overrides taken Branch",
                 32'h0000_0500,
                 32'h0000_0000,
                 32'h0000_0000,
                 32'h0000_0010,  // branch target
                 32'h0000_0040,  // jal target
                 1'b1, 1'b1, 1'b1, 1'b0,
                 32'h0000_0540,
                 32'h0000_0504);

        //=========================================================
        // TEST 8: Branch taken overrides PC+4
        //=========================================================
        run_test("Branch taken overrides PC+4",
                 32'h0000_0600,
                 32'h0000_0000,
                 32'h0000_0000,
                 32'hFFFF_FFF0,  // -16
                 32'h0000_0000,
                 1'b1, 1'b1, 1'b0, 1'b0,
                 32'h0000_05F0,
                 32'h0000_0604);

        //=========================================================
        // Final Summary Report
        //=========================================================
        $display("====================================================");
        $display(" PC_NEXT_LOGIC VERIFICATION REPORT");
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
