//=====================================================================
// File        : tb_pc_reg.v
// Author      : Prabhat Pandey
// Created On  : 13-Feb-2026
// Project     : RV32I Single-Cycle 32-bit RISC-V Processor
// Testbench   : tb_pc_reg
// Description :
//   Self-checking testbench for pc_reg.v
//
//   This testbench verifies:
//     1) Reset behavior (PC resets to 0)
//     2) PC update on clock rising edge
//     3) Multiple sequential PC updates
//     4) Reset asserted in the middle of operation
//
// Verification Features:
//   - Fully self-checking
//   - Input print for each test
//   - Expected output print
//   - Actual output print
//   - PASS/FAIL per test case
//   - Global counters for total/pass/fail
//   - Final verification summary report
//
// Run Commands:
//   iverilog -o ./Verification_Results/result_tb_pc_reg ./src/pc_reg.v ./RTL_Verification/tb_pc_reg.v
//   vvp ./Verification_Results/result_tb_pc_reg
//
//=====================================================================

`timescale 1ns/1ps

module tb_pc_reg;

    //=============================================================
    // Testbench Parameters
    //=============================================================
    localparam integer TEST_DELAY = 10; // ns between tests for waveform visibility

    //=============================================================
    // DUT Signals
    //=============================================================
    reg         clk;
    reg         rst_n;
    reg  [31:0] pc_next;
    wire [31:0] pc_current;

    //=============================================================
    // Instantiate DUT (Device Under Test)
    //=============================================================
    pc_reg dut (
        .clk        (clk),
        .rst_n      (rst_n),
        .pc_next    (pc_next),
        .pc_current (pc_current)
    );

    //=============================================================
    // Global Verification Counters
    //=============================================================
    integer total_tests;
    integer passed_tests;
    integer failed_tests;

    //=============================================================
    // VCD Dump (for GTKWave)
    //=============================================================
    initial begin
        $dumpfile("Verification_Results/vcd/tb_pc_reg.vcd");
        $dumpvars(0, tb_pc_reg);
    end

    //=============================================================
    // Clock Generation (10ns period)
    //=============================================================
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    //=============================================================
    // Task: Print Test Header Divider
    //=============================================================
    task print_divider;
        begin
            $display("----------------------------------------------------------------");
        end
    endtask

    //=============================================================
    // Task: Run a Single Test
    //=============================================================
    // Inputs:
    //   test_name     : string name of the test
    //   next_val      : value to apply to pc_next
    //   expected_pc   : expected value at pc_current AFTER posedge
    //   apply_reset   : 1 = assert reset before checking, 0 = normal
    //
    // Behavior:
    //   - Optionally asserts reset
    //   - Applies pc_next
    //   - Waits for posedge clk
    //   - Checks pc_current against expected
    //   - Prints PASS/FAIL
    //=============================================================
    task run_test;
        input [8*60:1] test_name;     // up to 60 chars
        input [31:0]   next_val;
        input [31:0]   expected_pc;
        input          apply_reset;

        reg [31:0] got_pc;
        begin
            total_tests = total_tests + 1;

            print_divider();
            $display("TEST : %s", test_name);

            // Optional reset assertion
            if (apply_reset) begin
                rst_n = 1'b0;
            end

            // Apply input
            pc_next = next_val;

            // Show Inputs
            $display("Inputs:");
            $display("   rst_n      = %0d", rst_n);
            $display("   pc_next    = %08h", pc_next);

            // Wait for rising edge so PC updates
            @(posedge clk);
            #1; // small delay to allow pc_current to settle

            got_pc = pc_current;

            // Print Expected vs Got
            $display("");
            $display("Expected:");
            $display("   pc_current = %08h", expected_pc);

            $display("");
            $display("Got:");
            $display("   pc_current = %08h", got_pc);

            // Compare
            if (got_pc === expected_pc) begin
                passed_tests = passed_tests + 1;
                $display("STATUS: PASS");
            end
            else begin
                failed_tests = failed_tests + 1;
                $display("STATUS: FAIL");
            end

            print_divider();
            $display("");

            // Deassert reset after test if it was applied
            if (apply_reset) begin
                rst_n = 1'b1;
            end

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
        rst_n   = 1'b0;
        pc_next = 32'h0000_0000;

        $display("====================================================");
        $display(" PC_REG VERIFICATION STARTED — Author: Prabhat Pandey");
        $display("====================================================");
        $display("");

        // ---------------------------------------------------------
        // TEST 1: Reset forces PC to 0
        // ---------------------------------------------------------
        // During reset, PC should become 0 on the next posedge.
        run_test("RESET behavior (PC must go to 0)", 32'hDEAD_BEEF, 32'h0000_0000, 1'b1);

        // ---------------------------------------------------------
        // TEST 2: Normal PC update after reset release
        // ---------------------------------------------------------
        // After reset is released, PC should load pc_next.
        run_test("PC update basic (load 0x00000004)", 32'h0000_0004, 32'h0000_0004, 1'b0);

        // ---------------------------------------------------------
        // TEST 3: Sequential update (multiple cycles)
        // ---------------------------------------------------------
        run_test("Sequential update (load 0x00000008)", 32'h0000_0008, 32'h0000_0008, 1'b0);
        run_test("Sequential update (load 0x0000000C)", 32'h0000_000C, 32'h0000_000C, 1'b0);

        // ---------------------------------------------------------
        // TEST 4: Large address update
        // ---------------------------------------------------------
        run_test("Large PC value (load 0x80000000)", 32'h8000_0000, 32'h8000_0000, 1'b0);

        // ---------------------------------------------------------
        // TEST 5: Reset asserted mid-run
        // ---------------------------------------------------------
        // Force reset again and verify PC becomes 0.
        run_test("Mid-run reset (PC must return to 0)", 32'h1234_5678, 32'h0000_0000, 1'b1);

        // ---------------------------------------------------------
        // TEST 6: Update after mid-run reset
        // ---------------------------------------------------------
        run_test("Post-reset update (load 0x00000100)", 32'h0000_0100, 32'h0000_0100, 1'b0);

        //=========================================================
        // Final Summary Report
        //=========================================================
        $display("====================================================");
        $display(" PC_REG VERIFICATION REPORT");
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
