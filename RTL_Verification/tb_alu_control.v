//=====================================================================
// File        : tb_alu_control.v
// Author      : Prabhat Pandey
// Created On  : 15-Feb-2026
// Project     : RV32I Single-Cycle 32-bit RISC-V Processor
// Testbench   : tb_alu_control
// Description :
//   Fully self-checking testbench for alu_control.v
//
// ALUOp Encoding (as defined in alu_control.v):
//   00 : Default ADD (loads/stores/address calc)
//   01 : Branch operation (SUB)
//   10 : R-type (OP) decode via funct3/funct7
//   11 : I-type (OP-IMM) decode via funct3/funct7
//
// ALUControl Encoding (must match alu.v):
//   0000 : ADD
//   0001 : SUB
//   0010 : AND
//   0011 : OR
//   0100 : XOR
//   0101 : SLT
//   0110 : SLTU
//   0111 : SLL
//   1000 : SRL
//   1001 : SRA
//
// Verification Features:
//   - Fully self-checking
//   - Input print per test
//   - Expected output print
//   - Actual output print
//   - PASS/FAIL per test
//   - Global counters
//   - Final summary report
//
// Run Commands:
//   iverilog -o ./Verification_Results/result_tb_alu_control ./src/alu_control.v ./RTL_Verification/tb_alu_control.v
//   vvp ./Verification_Results/result_tb_alu_control
//=====================================================================

`timescale 1ns/1ps

module tb_alu_control;

    //=============================================================
    // Testbench Parameters
    //=============================================================
    localparam integer TEST_DELAY = 10; // ns between tests for waveform visibility

    //=============================================================
    // DUT Signals
    //=============================================================
    reg  [1:0] alu_op;
    reg  [2:0] funct3;
    reg  [6:0] funct7;
    wire [3:0] alu_ctrl;

    //=============================================================
    // Instantiate DUT
    //=============================================================
    alu_control dut (
        .alu_op   (alu_op),
        .funct3   (funct3),
        .funct7   (funct7),
        .alu_ctrl (alu_ctrl)
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
        $dumpfile("Verification_Results/vcd/tb_alu_control.vcd");
        $dumpvars(0, tb_alu_control);
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
        input [1:0]    alu_op_in;
        input [2:0]    funct3_in;
        input [6:0]    funct7_in;
        input [3:0]    expected_ctrl;

        reg [3:0] got_ctrl;
        begin
            total_tests = total_tests + 1;

            print_divider();
            $display("TEST : %s", test_name);

            // Apply inputs
            alu_op = alu_op_in;
            funct3 = funct3_in;
            funct7 = funct7_in;

            #2; // combinational settle
            got_ctrl = alu_ctrl;

            // Print Inputs
            $display("Inputs:");
            $display("   alu_op   = %02b", alu_op_in);
            $display("   funct3   = %03b", funct3_in);
            $display("   funct7   = %07b", funct7_in);
            $display("   funct7[5]= %0d", funct7_in[5]);

            // Print Expected
            $display("");
            $display("Expected:");
            $display("   alu_ctrl = %04b", expected_ctrl);

            // Print Got
            $display("");
            $display("Got:");
            $display("   alu_ctrl = %04b", got_ctrl);

            // Compare
            if (got_ctrl === expected_ctrl) begin
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
        alu_op = 2'b00;
        funct3 = 3'b000;
        funct7 = 7'b0000000;

        $display("====================================================");
        $display(" ALU_CONTROL VERIFICATION STARTED — Author: Prabhat Pandey");
        $display("====================================================");
        $display("");

        //=========================================================
        // ALUOp = 00 : Always ADD
        //=========================================================
        run_test("ALUOp=00 default ADD (ignore funct fields)",
                 2'b00, 3'b111, 7'b1111111, 4'b0000);

        //=========================================================
        // ALUOp = 01 : Branch -> SUB
        //=========================================================
        run_test("ALUOp=01 branch -> SUB",
                 2'b01, 3'b000, 7'b0000000, 4'b0001);

        //=========================================================
        // ALUOp = 10 : R-type decoding
        //=========================================================

        // ADD
        run_test("R-type ADD (funct3=000, funct7=0000000)",
                 2'b10, 3'b000, 7'b0000000, 4'b0000);

        // SUB
        run_test("R-type SUB (funct3=000, funct7=0100000)",
                 2'b10, 3'b000, 7'b0100000, 4'b0001);

        // AND
        run_test("R-type AND (funct3=111)",
                 2'b10, 3'b111, 7'b0000000, 4'b0010);

        // OR
        run_test("R-type OR (funct3=110)",
                 2'b10, 3'b110, 7'b0000000, 4'b0011);

        // XOR
        run_test("R-type XOR (funct3=100)",
                 2'b10, 3'b100, 7'b0000000, 4'b0100);

        // SLT
        run_test("R-type SLT (funct3=010)",
                 2'b10, 3'b010, 7'b0000000, 4'b0101);

        // SLTU
        run_test("R-type SLTU (funct3=011)",
                 2'b10, 3'b011, 7'b0000000, 4'b0110);

        // SLL
        run_test("R-type SLL (funct3=001)",
                 2'b10, 3'b001, 7'b0000000, 4'b0111);

        // SRL
        run_test("R-type SRL (funct3=101, funct7[5]=0)",
                 2'b10, 3'b101, 7'b0000000, 4'b1000);

        // SRA
        run_test("R-type SRA (funct3=101, funct7[5]=1)",
                 2'b10, 3'b101, 7'b0100000, 4'b1001);

        //=========================================================
        // ALUOp = 11 : I-type OP-IMM decoding
        //=========================================================

        // ADDI
        run_test("I-type ADDI (funct3=000)",
                 2'b11, 3'b000, 7'b0000000, 4'b0000);

        // ANDI
        run_test("I-type ANDI (funct3=111)",
                 2'b11, 3'b111, 7'b0000000, 4'b0010);

        // ORI
        run_test("I-type ORI (funct3=110)",
                 2'b11, 3'b110, 7'b0000000, 4'b0011);

        // XORI
        run_test("I-type XORI (funct3=100)",
                 2'b11, 3'b100, 7'b0000000, 4'b0100);

        // SLTI
        run_test("I-type SLTI (funct3=010)",
                 2'b11, 3'b010, 7'b0000000, 4'b0101);

        // SLTIU
        run_test("I-type SLTIU (funct3=011)",
                 2'b11, 3'b011, 7'b0000000, 4'b0110);

        // SLLI
        run_test("I-type SLLI (funct3=001)",
                 2'b11, 3'b001, 7'b0000000, 4'b0111);

        // SRLI
        run_test("I-type SRLI (funct3=101, funct7[5]=0)",
                 2'b11, 3'b101, 7'b0000000, 4'b1000);

        // SRAI
        run_test("I-type SRAI (funct3=101, funct7[5]=1)",
                 2'b11, 3'b101, 7'b0100000, 4'b1001);

        //=========================================================
        // Default safety test
        //=========================================================
        run_test("Default safety: unknown ALUOp -> ADD",
                 2'bxx, 3'bxxx, 7'bxxxxxxx, 4'b0000);

        //=========================================================
        // Final Summary Report
        //=========================================================
        $display("====================================================");
        $display(" ALU_CONTROL VERIFICATION REPORT");
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
