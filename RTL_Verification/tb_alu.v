//=====================================================================
// File        : tb_alu.v
// Author      : Prabhat Pandey
// Created On  : 15-Feb-2026
// Project     : RV32I Single-Cycle 32-bit RISC-V Processor
// Testbench   : tb_alu
// Description :
//   Fully self-checking testbench for alu.v
//
// ALUControl Encoding (must match alu.v):
//   0000 : ADD
//   0001 : SUB
//   0010 : AND
//   0011 : OR
//   0100 : XOR
//   0101 : SLT   (signed)
//   0110 : SLTU  (unsigned)
//   0111 : SLL
//   1000 : SRL
//   1001 : SRA
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
//   iverilog -o ./Verification_Results/result_tb_alu ./src/alu.v ./RTL_Verification/tb_alu.v
//   vvp ./Verification_Results/result_tb_alu
//=====================================================================

`timescale 1ns/1ps

module tb_alu;

    //=============================================================
    // Testbench Parameters
    //=============================================================
    localparam integer TEST_DELAY = 10; // ns between tests for waveform visibility

    //=============================================================
    // DUT Signals
    //=============================================================
    reg  [31:0] A;
    reg  [31:0] B;
    reg  [3:0]  ALUControl;

    wire [31:0] Result;
    wire        Carry;
    wire        OverFlow;
    wire        Zero;
    wire        Negative;

    //=============================================================
    // Instantiate DUT
    //=============================================================
    alu dut (
        .A          (A),
        .B          (B),
        .ALUControl (ALUControl),
        .Result     (Result),
        .Carry      (Carry),
        .OverFlow   (OverFlow),
        .Zero       (Zero),
        .Negative   (Negative)
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
        $dumpfile("Verification_Results/vcd/tb_alu.vcd");
        $dumpvars(0, tb_alu);
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
    // Task: Run One ALU Test
    //=============================================================
    task run_test;
        input [8*60:1] test_name;
        input [31:0]   A_in;
        input [31:0]   B_in;
        input [3:0]    ctrl_in;

        input [31:0]   exp_result;
        input          exp_carry;
        input          exp_overflow;
        input          exp_zero;
        input          exp_negative;

        reg [31:0] got_result;
        reg        got_carry;
        reg        got_overflow;
        reg        got_zero;
        reg        got_negative;

        begin
            total_tests = total_tests + 1;

            print_divider();
            $display("TEST : %s", test_name);

            // Apply inputs
            A          = A_in;
            B          = B_in;
            ALUControl = ctrl_in;

            #2; // combinational settle

            // Sample outputs
            got_result   = Result;
            got_carry    = Carry;
            got_overflow = OverFlow;
            got_zero     = Zero;
            got_negative = Negative;

            // Print Inputs
            $display("Inputs:");
            $display("   A          = %08h", A_in);
            $display("   B          = %08h", B_in);
            $display("   ALUControl = %04b", ctrl_in);

            // Print Expected
            $display("");
            $display("Expected:");
            $display("   Result     = %08h", exp_result);
            $display("   Carry      = %0d", exp_carry);
            $display("   OverFlow   = %0d", exp_overflow);
            $display("   Zero       = %0d", exp_zero);
            $display("   Negative   = %0d", exp_negative);

            // Print Got
            $display("");
            $display("Got:");
            $display("   Result     = %08h", got_result);
            $display("   Carry      = %0d", got_carry);
            $display("   OverFlow   = %0d", got_overflow);
            $display("   Zero       = %0d", got_zero);
            $display("   Negative   = %0d", got_negative);

            // Compare
            if ((got_result   === exp_result)   &&
                (got_carry    === exp_carry)    &&
                (got_overflow === exp_overflow) &&
                (got_zero     === exp_zero)     &&
                (got_negative === exp_negative)) begin

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
        A          = 32'h0000_0000;
        B          = 32'h0000_0000;
        ALUControl = 4'b0000;

        $display("====================================================");
        $display(" ALU VERIFICATION STARTED — Author: Prabhat Pandey");
        $display("====================================================");
        $display("");

        //=========================================================
        // ADD TESTS (0000)
        //=========================================================
        run_test("ADD basic",
                 32'h0000_0005, 32'h0000_0007, 4'b0000,
                 32'h0000_000C, 1'b0, 1'b0, 1'b0, 1'b0);

        run_test("ADD wrap",
                 32'hFFFF_FFFF, 32'h0000_0001, 4'b0000,
                 32'h0000_0000, 1'b1, 1'b0, 1'b1, 1'b0);

        run_test("ADD signed overflow",
                 32'h7FFF_FFFF, 32'h0000_0001, 4'b0000,
                 32'h8000_0000, 1'b0, 1'b1, 1'b0, 1'b1);

        run_test("ADD negative + negative overflow",
                 32'h8000_0000, 32'h8000_0000, 4'b0000,
                 32'h0000_0000, 1'b1, 1'b1, 1'b1, 1'b0);

        //=========================================================
        // SUB TESTS (0001)
        //=========================================================
        run_test("SUB basic",
                 32'h0000_0014, 32'h0000_0007, 4'b0001,
                 32'h0000_000D, 1'b1, 1'b0, 1'b0, 1'b0);

        run_test("SUB negative result",
                 32'h0000_0007, 32'h0000_0014, 4'b0001,
                 32'hFFFF_FFF3, 1'b0, 1'b0, 1'b0, 1'b1);

        run_test("SUB signed overflow",
                 32'h8000_0000, 32'h0000_0001, 4'b0001,
                 32'h7FFF_FFFF, 1'b1, 1'b1, 1'b0, 1'b0);

        //=========================================================
        // AND TESTS (0010)
        //=========================================================
        run_test("AND test",
                 32'hF0F0_F0F0, 32'h0FF0_0FF0, 4'b0010,
                 32'h00F0_00F0, 1'b0, 1'b0, 1'b0, 1'b0);

        //=========================================================
        // OR TESTS (0011)
        //=========================================================
        run_test("OR test",
                 32'hA5A5_A5A5, 32'h0F0F_0F0F, 4'b0011,
                 32'hAFAF_AFAF, 1'b0, 1'b0, 1'b0, 1'b1);

        //=========================================================
        // XOR TESTS (0100)
        //=========================================================
        run_test("XOR test",
                 32'hAAAA_AAAA, 32'h5555_5555, 4'b0100,
                 32'hFFFF_FFFF, 1'b0, 1'b0, 1'b0, 1'b1);

        //=========================================================
        // SLT TESTS (0101)
        //=========================================================
        run_test("SLT -5 < 5",
                 32'hFFFF_FFFB, 32'h0000_0005, 4'b0101,
                 32'h0000_0001, 1'b0, 1'b0, 1'b0, 1'b0);

        run_test("SLT 5 < -5",
                 32'h0000_0005, 32'hFFFF_FFFB, 4'b0101,
                 32'h0000_0000, 1'b0, 1'b0, 1'b1, 1'b0);

        run_test("SLT min negative < 0",
                 32'h8000_0000, 32'h0000_0000, 4'b0101,
                 32'h0000_0001, 1'b0, 1'b0, 1'b0, 1'b0);

        //=========================================================
        // SLTU TESTS (0110)
        //=========================================================
        run_test("SLTU 1 < max",
                 32'h0000_0001, 32'hFFFF_FFFF, 4'b0110,
                 32'h0000_0001, 1'b0, 1'b0, 1'b0, 1'b0);

        run_test("SLTU max < 1",
                 32'hFFFF_FFFF, 32'h0000_0001, 4'b0110,
                 32'h0000_0000, 1'b0, 1'b0, 1'b1, 1'b0);

        run_test("SLTU unsigned compare",
                 32'h8000_0000, 32'h7FFF_FFFF, 4'b0110,
                 32'h0000_0000, 1'b0, 1'b0, 1'b1, 1'b0);

        //=========================================================
        // SLL TESTS (0111)
        //=========================================================
        run_test("SLL 1<<5",
                 32'h0000_0001, 32'h0000_0005, 4'b0111,
                 32'h0000_0020, 1'b0, 1'b0, 1'b0, 1'b0);

        run_test("SLL overflow shift",
                 32'hF000_0000, 32'h0000_0004, 4'b0111,
                 32'h0000_0000, 1'b0, 1'b0, 1'b1, 1'b0);

        //=========================================================
        // SRL TESTS (1000)
        //=========================================================
        run_test("SRL logical right",
                 32'h8000_0000, 32'h0000_001F, 4'b1000,
                 32'h0000_0001, 1'b0, 1'b0, 1'b0, 1'b0);

        run_test("SRL shift",
                 32'hFFFF_FFFF, 32'h0000_0004, 4'b1000,
                 32'h0FFF_FFFF, 1'b0, 1'b0, 1'b0, 1'b0);

        //=========================================================
        // SRA TESTS (1001)
        //=========================================================
        run_test("SRA arithmetic",
                 32'hFFFF_FFFF, 32'h0000_0004, 4'b1001,
                 32'hFFFF_FFFF, 1'b0, 1'b0, 1'b0, 1'b1);

        run_test("SRA sign extend",
                 32'h8000_0000, 32'h0000_001F, 4'b1001,
                 32'hFFFF_FFFF, 1'b0, 1'b0, 1'b0, 1'b1);

        //=========================================================
        // Zero flag test (ADD)
        //=========================================================
        run_test("Zero flag test",
                 32'h0000_000A, 32'hFFFF_FFF6, 4'b0000,
                 32'h0000_0000, 1'b1, 1'b0, 1'b1, 1'b0);

        //=========================================================
        // Final Summary Report
        //=========================================================
        $display("====================================================");
        $display(" ALU VERIFICATION REPORT");
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
