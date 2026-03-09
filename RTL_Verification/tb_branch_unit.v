//=====================================================================
// File        : tb_branch_unit.v
// Author      : Prabhat Pandey
// Created On  : 16-Feb-2026
// Project     : RV32I Single-Cycle 32-bit RISC-V Processor
// Testbench   : tb_branch_unit
// Description :
//   Fully self-checking testbench for branch_unit.v
//
// Branch funct3 encoding (RV32I):
//   000 : BEQ
//   001 : BNE
//   100 : BLT   (signed)
//   101 : BGE   (signed)
//   110 : BLTU  (unsigned)
//   111 : BGEU  (unsigned)
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
//   iverilog -o ./Verification_Results/result_tb_branch_unit ./src/branch_unit.v ./RTL_Verification/tb_branch_unit.v
//   vvp ./Verification_Results/result_tb_branch_unit
//=====================================================================

`timescale 1ns/1ps

module tb_branch_unit;

    //=============================================================
    // Testbench Parameters
    //=============================================================
    localparam integer TEST_DELAY = 10; // ns between tests for waveform visibility

    //=============================================================
    // DUT Signals
    //=============================================================
    reg  [2:0]  funct3;
    reg  [31:0] rs1_val;
    reg  [31:0] rs2_val;
    wire        take_branch;

    //=============================================================
    // Instantiate DUT
    //=============================================================
    branch_unit dut (
        .funct3      (funct3),
        .rs1_val     (rs1_val),
        .rs2_val     (rs2_val),
        .take_branch (take_branch)
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
        $dumpfile("Verification_Results/vcd/tb_branch_unit.vcd");
        $dumpvars(0, tb_branch_unit);
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
    // Task: Run One Branch Test
    //=============================================================
    task run_test;
        input [8*70:1] test_name;
        input [2:0]    funct3_in;
        input [31:0]   rs1_in;
        input [31:0]   rs2_in;
        input          expected_take;

        reg got_take;
        begin
            total_tests = total_tests + 1;

            print_divider();
            $display("TEST : %s", test_name);

            // Apply inputs
            funct3  = funct3_in;
            rs1_val = rs1_in;
            rs2_val = rs2_in;

            #2; // combinational settle
            got_take = take_branch;

            // Print Inputs
            $display("Inputs:");
            $display("   funct3      = %03b", funct3_in);
            $display("   rs1_val     = %08h", rs1_in);
            $display("   rs2_val     = %08h", rs2_in);
            $display("   rs1 signed  = %0d", $signed(rs1_in));
            $display("   rs2 signed  = %0d", $signed(rs2_in));

            // Print Expected
            $display("");
            $display("Expected:");
            $display("   take_branch = %0d", expected_take);

            // Print Got
            $display("");
            $display("Got:");
            $display("   take_branch = %0d", got_take);

            // Compare
            if (got_take === expected_take) begin
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
        funct3  = 3'b000;
        rs1_val = 32'h0000_0000;
        rs2_val = 32'h0000_0000;

        $display("====================================================");
        $display(" BRANCH_UNIT VERIFICATION STARTED — Author: Prabhat Pandey");
        $display("====================================================");
        $display("");

        //=========================================================
        // BEQ tests
        //=========================================================
        run_test("BEQ true (equal)",
                 3'b000, 32'h0000_0010, 32'h0000_0010, 1'b1);

        run_test("BEQ false (not equal)",
                 3'b000, 32'h0000_0010, 32'h0000_0011, 1'b0);

        //=========================================================
        // BNE tests
        //=========================================================
        run_test("BNE true (not equal)",
                 3'b001, 32'h0000_0010, 32'h0000_0011, 1'b1);

        run_test("BNE false (equal)",
                 3'b001, 32'hABCD_EF01, 32'hABCD_EF01, 1'b0);

        //=========================================================
        // BLT (signed) tests
        //=========================================================
        run_test("BLT signed: -5 < 5 (true)",
                 3'b100, 32'hFFFF_FFFB, 32'h0000_0005, 1'b1);

        run_test("BLT signed: 5 < -5 (false)",
                 3'b100, 32'h0000_0005, 32'hFFFF_FFFB, 1'b0);

        run_test("BLT signed: -10 < -5 (true)",
                 3'b100, 32'hFFFF_FFF6, 32'hFFFF_FFFB, 1'b1);

        //=========================================================
        // BGE (signed) tests
        //=========================================================
        run_test("BGE signed: 5 >= 5 (true)",
                 3'b101, 32'h0000_0005, 32'h0000_0005, 1'b1);

        run_test("BGE signed: 5 >= -5 (true)",
                 3'b101, 32'h0000_0005, 32'hFFFF_FFFB, 1'b1);

        run_test("BGE signed: -5 >= 5 (false)",
                 3'b101, 32'hFFFF_FFFB, 32'h0000_0005, 1'b0);

        run_test("BGE signed: -5 >= -10 (true)",
                 3'b101, 32'hFFFF_FFFB, 32'hFFFF_FFF6, 1'b1);

        //=========================================================
        // BLTU (unsigned) tests
        //=========================================================
        run_test("BLTU unsigned: 1 < 2 (true)",
                 3'b110, 32'h0000_0001, 32'h0000_0002, 1'b1);

        run_test("BLTU unsigned: 2 < 1 (false)",
                 3'b110, 32'h0000_0002, 32'h0000_0001, 1'b0);

        // This is the classic tricky case:
        // 0x80000000 is negative signed, but very large unsigned.
        run_test("BLTU unsigned: 0x80000000 < 0x7FFFFFFF (false)",
                 3'b110, 32'h8000_0000, 32'h7FFF_FFFF, 1'b0);

        run_test("BLTU unsigned: 0x7FFFFFFF < 0x80000000 (true)",
                 3'b110, 32'h7FFF_FFFF, 32'h8000_0000, 1'b1);

        //=========================================================
        // BGEU (unsigned) tests
        //=========================================================
        run_test("BGEU unsigned: 5 >= 5 (true)",
                 3'b111, 32'h0000_0005, 32'h0000_0005, 1'b1);

        run_test("BGEU unsigned: 10 >= 5 (true)",
                 3'b111, 32'h0000_000A, 32'h0000_0005, 1'b1);

        run_test("BGEU unsigned: 5 >= 10 (false)",
                 3'b111, 32'h0000_0005, 32'h0000_000A, 1'b0);

        run_test("BGEU unsigned: 0x80000000 >= 0x7FFFFFFF (true)",
                 3'b111, 32'h8000_0000, 32'h7FFF_FFFF, 1'b1);

        //=========================================================
        // Default funct3 test (invalid funct3)
        //=========================================================
        run_test("Invalid funct3 -> take_branch must be 0",
                 3'b010, 32'h0000_0001, 32'h0000_0001, 1'b0);

        //=========================================================
        // Final Summary Report
        //=========================================================
        $display("====================================================");
        $display(" BRANCH_UNIT VERIFICATION REPORT");
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
