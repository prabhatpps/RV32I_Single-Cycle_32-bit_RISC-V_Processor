//=====================================================================
// File        : tb_imem_program_2.v
// Author      : Prabhat Pandey
// Created On  : 25-Feb-2026
// Project     : RV32I Single-Cycle 32-bit RISC-V Processor
// Testbench   : tb_imem_program_2
// Description :
//   Fully self-checking testbench for imem.v using program_2.hex
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
//   iverilog -o ./Verification_Results/result_tb_imem_program_2 \
//       ./src/imem.v ./RTL_Verification/tb_imem_program_2.v
//
//   vvp ./Verification_Results/result_tb_imem_program_2
//
// IMPORTANT:
//   This testbench loads program_2.hex into DUT memory (simulation-only).
//   Ensure program_2.hex is present in the simulation working directory.
//=====================================================================

`timescale 1ns/1ps

module tb_imem_program_2;

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
        .MEM_DEPTH_WORDS(4096)
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
        $dumpfile("Verification_Results/vcd/tb_imem_program_2.vcd");
        $dumpvars(0, tb_imem_program_2);
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
    integer idx;
    reg [31:0] expected_instr [0:20];
    reg [31:0] expected_addr  [0:20];
    reg [8*80:1] step_name    [0:20];

    initial begin

        // Init counters
        total_tests  = 0;
        passed_tests = 0;
        failed_tests = 0;

        // Init inputs
        addr = 32'h0000_0000;

        // Load program into IMEM (simulation-only)
        $readmemh("program_2.hex", dut.mem);

        $display("====================================================");
        $display(" IMEM VERIFICATION STARTED — Author: Prabhat Pandey");
        $display("====================================================");
        $display("");

        // ----------------------------------------------------------
        // program_2.hex reference:
        // Index 0  : 00000013
        // Index 1  : 00a00093
        // Index 2  : 01400113
        // Index 3  : 002081b3
        // Index 4  : 40208233
        // Index 5  : 0ff3f293
        // Index 6  : 0f016313
        // Index 7  : 0552c393
        // Index 8  : 00209413
        // Index 9  : 0011d493
        // Index 10 : 00f0a513
        // Index 11 : 019135b3
        // Index 12 : 00302023
        // Index 13 : 00002603
        // Index 14 : 00c18463
        // Index 15 : 06300693
        // Index 16 : 008007ef
        // Index 17 : 12345737
        // Index 18 : 00000817
        // Index 19 : 00100893
        // Index 20 : fe0006e3
        // ----------------------------------------------------------

        // Expected full program fetch list
        expected_addr[0]  = 32'h0000_0000;
        expected_instr[0] = 32'h0000_0013;
        step_name[0]      = "Fetch: NOP (ADDI x0, x0, 0) @ PC=0x00000000";

        expected_addr[1]  = 32'h0000_0004;
        expected_instr[1] = 32'h00a0_0093;
        step_name[1]      = "Fetch: ADDI x1, x0, 10 @ PC=0x00000004";

        expected_addr[2]  = 32'h0000_0008;
        expected_instr[2] = 32'h0140_0113;
        step_name[2]      = "Fetch: ADDI x2, x0, 20 @ PC=0x00000008";

        expected_addr[3]  = 32'h0000_000C;
        expected_instr[3] = 32'h0020_81b3;
        step_name[3]      = "Fetch: ADD x3, x1, x2 @ PC=0x0000000C";

        expected_addr[4]  = 32'h0000_0010;
        expected_instr[4] = 32'h4020_8233;
        step_name[4]      = "Fetch: SUB x4, x1, x2 @ PC=0x00000010";

        expected_addr[5]  = 32'h0000_0014;
        expected_instr[5] = 32'h0ff3_f293;
        step_name[5]      = "Fetch: ANDI x5, x7, 255 @ PC=0x00000014";

        expected_addr[6]  = 32'h0000_0018;
        expected_instr[6] = 32'h0f01_6313;
        step_name[6]      = "Fetch: ORI x6, x2, 240 @ PC=0x00000018";

        expected_addr[7]  = 32'h0000_001C;
        expected_instr[7] = 32'h0552_c393;
        step_name[7]      = "Fetch: XORI x7, x5, 85 @ PC=0x0000001C";

        expected_addr[8]  = 32'h0000_0020;
        expected_instr[8] = 32'h0020_9413;
        step_name[8]      = "Fetch: SLLI x8, x1, 2 @ PC=0x00000020";

        expected_addr[9]  = 32'h0000_0024;
        expected_instr[9] = 32'h0011_d493;
        step_name[9]      = "Fetch: SRLI x9, x3, 1 @ PC=0x00000024";

        expected_addr[10]  = 32'h0000_0028;
        expected_instr[10] = 32'h00f0_a513;
        step_name[10]      = "Fetch: SLTI x10, x1, 15 @ PC=0x00000028";

        expected_addr[11]  = 32'h0000_002C;
        expected_instr[11] = 32'h0191_35b3;
        step_name[11]      = "Fetch: SLTU x11, x2, x25 @ PC=0x0000002C";

        expected_addr[12]  = 32'h0000_0030;
        expected_instr[12] = 32'h0030_2023;
        step_name[12]      = "Fetch: SW x3, 0(x0) @ PC=0x00000030";

        expected_addr[13]  = 32'h0000_0034;
        expected_instr[13] = 32'h0000_2603;
        step_name[13]      = "Fetch: LW x12, 0(x0) @ PC=0x00000034";

        expected_addr[14]  = 32'h0000_0038;
        expected_instr[14] = 32'h00c1_8463;
        step_name[14]      = "Fetch: BEQ x3, x12, +8 @ PC=0x00000038";

        expected_addr[15]  = 32'h0000_003C;
        expected_instr[15] = 32'h0630_0693;
        step_name[15]      = "Fetch: ADDI x13, x0, 99 @ PC=0x0000003C";

        expected_addr[16]  = 32'h0000_0040;
        expected_instr[16] = 32'h0080_07ef;
        step_name[16]      = "Fetch: JAL x15, +8 @ PC=0x00000040";

        expected_addr[17]  = 32'h0000_0044;
        expected_instr[17] = 32'h1234_5737;
        step_name[17]      = "Fetch: LUI x14, 0x12345 @ PC=0x00000044";

        expected_addr[18]  = 32'h0000_0048;
        expected_instr[18] = 32'h0000_0817;
        step_name[18]      = "Fetch: AUIPC x16, 0x0 @ PC=0x00000048";

        expected_addr[19]  = 32'h0000_004C;
        expected_instr[19] = 32'h0010_0893;
        step_name[19]      = "Fetch: ADDI x17, x0, 1 @ PC=0x0000004C";

        expected_addr[20]  = 32'h0000_0050;
        expected_instr[20] = 32'hfe00_06e3;
        step_name[20]      = "Fetch: BEQ x0, x0, -20 @ PC=0x00000050";

        // Full program fetch verification
        for (idx = 0; idx <= 20; idx = idx + 1) begin
            run_test(step_name[idx], expected_addr[idx], expected_instr[idx]);
        end

        // Test: word addressing behavior
        // PC=0x00000005 should still index word 1 because addr[31:2] = 1
        // (In real CPU PC won't be unaligned, but we verify indexing logic)
        run_test("Unaligned addr -> word 1 (ADDI x1, x0, 10)", 32'h0000_0005, 32'h00a0_0093);

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
