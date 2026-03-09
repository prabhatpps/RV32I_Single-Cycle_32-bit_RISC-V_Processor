//=====================================================================
// File        : tb_imem_program_1.v
// Author      : Prabhat Pandey
// Created On  : 25-Feb-2026
// Project     : RV32I Single-Cycle 32-bit RISC-V Processor
// Testbench   : tb_imem_program_1
// Description :
//   Fully self-checking testbench for imem.v using program_1.hex
//
//   This testbench verifies:
//     1) Instruction memory reads correct 32-bit words
//     2) Addressing is word-based (addr[31:2])
//     3) Multiple sequential fetches return expected values
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
//   iverilog -o ./Verification_Results/result_tb_imem_program_1 \
//       ./src/imem.v ./RTL_Verification/tb_imem_program_1.v
//
//   vvp ./Verification_Results/result_tb_imem_program_1
//
// IMPORTANT:
//   This testbench loads program_1.hex into DUT memory (simulation-only).
//   Ensure program_1.hex is present in the simulation working directory.
//=====================================================================

`timescale 1ns/1ps

module tb_imem_program_1;

    //=============================================================
    // Testbench Parameters
    //=============================================================
    localparam integer TEST_DELAY = 10; // ns between tests for waveform visibility

    //=============================================================
    // DUT Signals
    //=============================================================
    reg  [31:0] addr;
    wire [31:0] instr;

    //=============================================================
    // Instantiate DUT
    //=============================================================
    imem #(
        .MEM_DEPTH_WORDS(1024)
    ) dut (
        .addr  (addr),
        .instr (instr)
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
        $dumpfile("Verification_Results/vcd/tb_imem_program_1.vcd");
        $dumpvars(0, tb_imem_program_1);
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
    // Task: Run a Single IMEM Read Test
    //=============================================================
    // Inputs:
    //   test_name      : string name of the test
    //   addr_in        : byte address applied to IMEM
    //   expected_instr : expected 32-bit instruction output
    //
    // Behavior:
    //   - Applies addr
    //   - Waits small time for combinational propagation
    //   - Checks instr
    //   - Prints PASS/FAIL
    //=============================================================
    task run_test;
        input [8*60:1] test_name;
        input [31:0]   addr_in;
        input [31:0]   expected_instr;

        reg [31:0] got_instr;
        begin
            total_tests = total_tests + 1;

            print_divider();
            $display("TEST : %s", test_name);

            // Apply input address
            addr = addr_in;

            // Wait for combinational output to settle
            #2;
            got_instr = instr;

            // Print Inputs
            $display("Inputs:");
            $display("   addr (byte) = %08h", addr_in);
            $display("   addr[31:2]  = %08h", addr_in >> 2);

            // Print Expected
            $display("");
            $display("Expected:");
            $display("   instr       = %08h", expected_instr);

            // Print Got
            $display("");
            $display("Got:");
            $display("   instr       = %08h", got_instr);

            // Compare
            if (got_instr === expected_instr) begin
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
        addr = 32'h0000_0000;

        // Load program into IMEM (simulation-only)
        $readmemh("program_1.hex", dut.mem);

        $display("====================================================");
        $display(" IMEM VERIFICATION STARTED — Author: Prabhat Pandey");
        $display("====================================================");
        $display("");

        // ----------------------------------------------------------
        // program_1.hex reference:
        // Index 0 : 00000013
        // Index 1 : 00100093
        // Index 2 : 00200113
        // Index 3 : 00308193
        // Index 4 : 00410213
        // ...
        // ----------------------------------------------------------

        // Basic sequential fetch tests
        run_test("Fetch word 0 (PC=0x00000000)", 32'h0000_0000, 32'h0000_0013);
        run_test("Fetch word 1 (PC=0x00000004)", 32'h0000_0004, 32'h0010_0093);
        run_test("Fetch word 2 (PC=0x00000008)", 32'h0000_0008, 32'h0020_0113);
        run_test("Fetch word 3 (PC=0x0000000C)", 32'h0000_000C, 32'h0030_8193);
        run_test("Fetch word 4 (PC=0x00000010)", 32'h0000_0010, 32'h0041_0213);

        // Test: word addressing behavior
        // PC=0x00000005 should still index word 1 because addr[31:2] = 1
        // (In real CPU PC won't be unaligned, but we verify indexing logic)
        run_test("Unaligned addr test (0x00000005 -> word 1)", 32'h0000_0005, 32'h0010_0093);

        // Test: higher addresses
        run_test("Fetch word 10 (PC=0x00000028)", 32'h0000_0028, 32'h00a4_0513);
        run_test("Fetch word 15 (PC=0x0000003C)", 32'h0000_003C, 32'h00f6_8793);

        //=========================================================
        // Final Summary Report
        //=========================================================
        $display("====================================================");
        $display(" IMEM VERIFICATION REPORT");
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
