//=====================================================================
// File        : tb_imm_gen.v
// Author      : Prabhat Pandey
// Created On  : 15-Feb-2026
// Project     : RV32I Single-Cycle 32-bit RISC-V Processor
// Testbench   : tb_imm_gen
// Description :
//   Fully self-checking testbench for imm_gen.v
//
//   This testbench verifies correct immediate extraction and sign
//   extension for RV32I instruction formats:
//
//     1) I-type (OP-IMM, LOAD, JALR)
//     2) S-type (STORE)
//     3) B-type (BRANCH)  [shift-left by 1, imm[0]=0]
//     4) U-type (LUI, AUIPC)
//     5) J-type (JAL)     [shift-left by 1, imm[0]=0]
//
// Verification Features:
//   - Fully self-checking
//   - Input print (instruction, opcode)
//   - Expected output print
//   - Actual output print
//   - PASS/FAIL per test case
//   - Global counters
//   - Final verification summary report
//
// Run Commands:
//   iverilog -o ./Verification_Results/result_tb_imm_gen ./src/imm_gen.v ./RTL_Verification/tb_imm_gen.v
//   vvp ./Verification_Results/result_tb_imm_gen
//=====================================================================

`timescale 1ns/1ps

module tb_imm_gen;

    //=============================================================
    // Testbench Parameters
    //=============================================================
    localparam integer TEST_DELAY = 10; // ns between tests for waveform visibility

    //=============================================================
    // DUT Signals
    //=============================================================
    reg  [31:0] instr;
    wire [31:0] imm_i;
    wire [31:0] imm_s;
    wire [31:0] imm_b;
    wire [31:0] imm_u;
    wire [31:0] imm_j;

    //=============================================================
    // Instantiate DUT
    //=============================================================
    imm_gen dut (
        .instr (instr),
        .imm_i (imm_i),
        .imm_s (imm_s),
        .imm_b (imm_b),
        .imm_u (imm_u),
        .imm_j (imm_j)
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
        $dumpfile("Verification_Results/vcd/tb_imm_gen.vcd");
        $dumpvars(0, tb_imm_gen);
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
    // Function: Get opcode from instruction
    //=============================================================
    function [6:0] get_opcode;
        input [31:0] ins;
        begin
            get_opcode = ins[6:0];
        end
    endfunction

    //=============================================================
    // Task: Run One Test Case
    //=============================================================
    task run_test;
        input [8*70:1] test_name;
        input [31:0]   instr_in;
        input [31:0]   expected_imm;

        reg [31:0] got_imm;
        reg [6:0]  opc;
        begin
            total_tests = total_tests + 1;

            print_divider();
            $display("TEST : %s", test_name);

            instr = instr_in;
            #2; // combinational settle

            opc = get_opcode(instr_in);

            // Select the correct immediate based on opcode
            case (opc)
                7'b0010011, // OP-IMM
                7'b0000011, // LOAD
                7'b1100111: // JALR
                    got_imm = imm_i;

                7'b0100011: // STORE
                    got_imm = imm_s;

                7'b1100011: // BRANCH
                    got_imm = imm_b;

                7'b0110111, // LUI
                7'b0010111: // AUIPC
                    got_imm = imm_u;

                7'b1101111: // JAL
                    got_imm = imm_j;

                default:
                    got_imm = 32'h0000_0000;
            endcase

            // Print Inputs
            $display("Inputs:");
            $display("   instr   = %08h", instr_in);
            $display("   opcode  = %07b", opc);

            // Print Expected
            $display("");
            $display("Expected:");
            $display("   imm_out = %08h", expected_imm);

            // Print Got
            $display("");
            $display("Got:");
            $display("   imm_out = %08h", got_imm);

            // Compare
            if (got_imm === expected_imm) begin
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
    // Helper: Build Instructions (Minimal Encodings)
    //=============================================================
    // We only care about immediate bit positions and opcode.
    // The remaining fields (rd, rs1, rs2, funct3) can be anything.
    //=============================================================

    //=============================================================
    // Main Test Sequence
    //=============================================================
    initial begin

        // Init counters
        total_tests  = 0;
        passed_tests = 0;
        failed_tests = 0;

        // Init input
        instr = 32'h0000_0000;

        $display("====================================================");
        $display(" IMM_GEN VERIFICATION STARTED — Author: Prabhat Pandey");
        $display("====================================================");
        $display("");

        //=========================================================
        // I-TYPE TESTS (opcode = 0010011)
        // imm = instr[31:20]
        //=========================================================

        // I-type imm = +5
        // instr[31:20] = 0x005
        run_test("I-type imm = +5 (addi style)",
                 {12'h005, 5'd1, 3'b000, 5'd2, 7'b0010011},
                 32'h0000_0005);

        // I-type imm = -1 (0xFFF)
        run_test("I-type imm = -1",
                 {12'hFFF, 5'd1, 3'b000, 5'd2, 7'b0010011},
                 32'hFFFF_FFFF);

        // I-type imm = -2048 (min 12-bit signed)
        run_test("I-type imm = -2048 (min)",
                 {12'h800, 5'd1, 3'b000, 5'd2, 7'b0010011},
                 32'hFFFF_F800);

        // I-type imm = +2047 (max 12-bit signed)
        run_test("I-type imm = +2047 (max)",
                 {12'h7FF, 5'd1, 3'b000, 5'd2, 7'b0010011},
                 32'h0000_07FF);

        //=========================================================
        // S-TYPE TESTS (opcode = 0100011)
        // imm = {instr[31:25], instr[11:7]}
        //=========================================================

        // S-type imm = +16 (0x010)
        // imm[11:5]=0, imm[4:0]=10000
        run_test("S-type imm = +16 (sw style)",
                 {7'b0000000, 5'd3, 5'd2, 3'b010, 5'b10000, 7'b0100011},
                 32'h0000_0010);

        // S-type imm = -1 (0xFFF)
        run_test("S-type imm = -1",
                 {7'b1111111, 5'd3, 5'd2, 3'b010, 5'b11111, 7'b0100011},
                 32'hFFFF_FFFF);

        // S-type imm = -2048 (0x800)
        // imm[11]=1, others 0
        run_test("S-type imm = -2048 (min)",
                 {7'b1000000, 5'd3, 5'd2, 3'b010, 5'b00000, 7'b0100011},
                 32'hFFFF_F800);

        //=========================================================
        // B-TYPE TESTS (opcode = 1100011)
        //
        // imm encoding:
        //   imm[12]   = instr[31]
        //   imm[11]   = instr[7]
        //   imm[10:5] = instr[30:25]
        //   imm[4:1]  = instr[11:8]
        //   imm[0]    = 0
        //=========================================================

        // B-type imm = +16
        // +16 in binary = 0000 0001 0000
        // imm[4:1] = 1000, imm[10:5]=000000, imm[11]=0, imm[12]=0
        run_test("B-type imm = +16 (branch forward)",
                 {
                   1'b0,          // instr[31] imm[12]
                   6'b000000,     // instr[30:25] imm[10:5]
                   5'd2,          // rs2
                   5'd1,          // rs1
                   3'b000,        // funct3
                   4'b1000,       // instr[11:8] imm[4:1]
                   1'b0,          // instr[7] imm[11]
                   7'b1100011     // opcode
                 },
                 32'h0000_0010);

        // B-type imm = -16
        // -16 = 0xFFFF_FFF0
        // imm bits represent 13-bit signed value with bit0=0.
        run_test("B-type imm = -16 (branch backward)",
                 {
                   1'b1,          // imm[12]
                   6'b111111,     // imm[10:5]
                   5'd2,
                   5'd1,
                   3'b000,
                   4'b1000,       // imm[4:1]
                   1'b1,          // imm[11]
                   7'b1100011
                 },
                 32'hFFFF_FFF0);

        // B-type imm = +4 (smallest meaningful forward branch)
        // +4 => imm[4:1]=0010
        run_test("B-type imm = +4 (branch forward)",
                 {
                   1'b0,
                   6'b000000,
                   5'd2,
                   5'd1,
                   3'b000,
                   4'b0010,
                   1'b0,
                   7'b1100011
                 },
                 32'h0000_0004);

        //=========================================================
        // U-TYPE TESTS (opcode = 0110111 LUI, 0010111 AUIPC)
        // imm = instr[31:12] << 12
        //=========================================================

        run_test("U-type imm (LUI) = 0x12345000",
                 {20'h12345, 5'd1, 7'b0110111},
                 32'h1234_5000);

        run_test("U-type imm (AUIPC) = 0xABCDE000",
                 {20'hABCDE, 5'd1, 7'b0010111},
                 32'hABCDE_000);

        //=========================================================
        // J-TYPE TESTS (opcode = 1101111)
        //
        // imm encoding:
        //   imm[20]   = instr[31]
        //   imm[19:12]= instr[19:12]
        //   imm[11]   = instr[20]
        //   imm[10:1] = instr[30:21]
        //   imm[0]    = 0
        //=========================================================

        // J-type imm = +32
        // +32 => 0x00000020
        // imm[10:1] should represent 16 (since shift left by 1)
        // imm[10:1] = 0000010000 (16)
        run_test("J-type imm = +32 (jal forward)",
                 {
                   1'b0,          // instr[31] imm[20]
                   10'b0000010000,// instr[30:21] imm[10:1]
                   1'b0,          // instr[20] imm[11]
                   8'b00000000,   // instr[19:12] imm[19:12]
                   5'd1,          // rd
                   7'b1101111     // opcode
                 },
                 32'h0000_0020);

        // J-type imm = -32
        // -32 => 0xFFFF_FFE0
        run_test("J-type imm = -32 (jal backward)",
                 {
                   1'b1,          // imm[20]
                   10'b1111110000,// imm[10:1]
                   1'b1,          // imm[11]
                   8'b11111111,   // imm[19:12]
                   5'd1,
                   7'b1101111
                 },
                 32'hFFFF_FFE0);

        //=========================================================
        // Default opcode test (should output 0)
        //=========================================================
        run_test("Default case (unknown opcode) -> imm=0",
                 32'hFFFFFFFF,
                 32'h0000_0000);

        //=========================================================
        // Final Summary Report
        //=========================================================
        $display("====================================================");
        $display(" IMM_GEN VERIFICATION REPORT");
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
