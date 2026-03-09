//=====================================================================
// File        : tb_wb_mux.v
// Author      : Prabhat Pandey
// Created On  : 16-Feb-2026
// Project     : RV32I Single-Cycle 32-bit RISC-V Processor
// Testbench   : tb_wb_mux
// Description :
//   Fully self-checking testbench for wb_mux.v
//
// wb_sel Encoding:
//   000 : ALU result
//   001 : Memory read data
//   010 : PC + 4
//   011 : U-immediate (LUI)
//   100 : PC + immediate (AUIPC)
//   others : 0 (safe)
//
// Verification Features:
//   - Fully self-checking
//   - Input print per test
//   - Expected output print
//   - Actual output print
//   - PASS/FAIL per test case
//   - Global counters
//   - Final verification summary report
//
// Run Commands:
//   iverilog -o ./Verification_Results/result_tb_wb_mux ./src/wb_mux.v ./RTL_Verification/tb_wb_mux.v
//   vvp ./Verification_Results/result_tb_wb_mux
//=====================================================================

`timescale 1ns/1ps

module tb_wb_mux;

    //=============================================================
    // Testbench Parameters
    //=============================================================
    localparam integer TEST_DELAY = 10; // ns between tests for waveform visibility

    //=============================================================
    // DUT Inputs
    //=============================================================
    reg  [2:0]  wb_sel;
    reg  [31:0] alu_result;
    reg  [31:0] mem_data;
    reg  [31:0] pc_plus4;
    reg  [31:0] u_imm;
    reg  [31:0] pc_plus_imm;

    //=============================================================
    // DUT Output
    //=============================================================
    wire [31:0] wb_data;

    //=============================================================
    // Instantiate DUT
    //=============================================================
    wb_mux dut (
        .wb_sel      (wb_sel),
        .alu_result  (alu_result),
        .mem_data    (mem_data),
        .pc_plus4    (pc_plus4),
        .u_imm       (u_imm),
        .pc_plus_imm (pc_plus_imm),
        .wb_data     (wb_data)
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
        $dumpfile("Verification_Results/vcd/tb_wb_mux.vcd");
        $dumpvars(0, tb_wb_mux);
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

        input [2:0]  wb_sel_in;
        input [31:0] alu_in;
        input [31:0] mem_in;
        input [31:0] pc4_in;
        input [31:0] uimm_in;
        input [31:0] pcimm_in;

        input [31:0] expected_wb;

        reg [31:0] got_wb;
        begin
            total_tests = total_tests + 1;

            print_divider();
            $display("TEST : %s", test_name);

            // Apply inputs
            wb_sel      = wb_sel_in;
            alu_result  = alu_in;
            mem_data    = mem_in;
            pc_plus4    = pc4_in;
            u_imm       = uimm_in;
            pc_plus_imm = pcimm_in;

            #2; // settle

            got_wb = wb_data;

            // Print Inputs
            $display("Inputs:");
            $display("   wb_sel      = %03b", wb_sel_in);
            $display("   alu_result  = %08h", alu_in);
            $display("   mem_data    = %08h", mem_in);
            $display("   pc_plus4    = %08h", pc4_in);
            $display("   u_imm       = %08h", uimm_in);
            $display("   pc_plus_imm = %08h", pcimm_in);

            // Print Expected
            $display("");
            $display("Expected:");
            $display("   wb_data     = %08h", expected_wb);

            // Print Got
            $display("");
            $display("Got:");
            $display("   wb_data     = %08h", got_wb);

            // Compare
            if (got_wb === expected_wb) begin
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
        wb_sel      = 3'b000;
        alu_result  = 32'h0000_0000;
        mem_data    = 32'h0000_0000;
        pc_plus4    = 32'h0000_0000;
        u_imm       = 32'h0000_0000;
        pc_plus_imm = 32'h0000_0000;

        $display("====================================================");
        $display(" WB_MUX VERIFICATION STARTED — Author: Prabhat Pandey");
        $display("====================================================");
        $display("");

        // Common test values (easy to track)
        // ALU   = 0xAAAAAAAA
        // MEM   = 0xBBBBBBBB
        // PC+4  = 0x00000044
        // UIMM  = 0x12345000
        // PCIMM = 0x00001000
        //=========================================================

        //=========================================================
        // wb_sel = 000 -> ALU
        //=========================================================
        run_test("wb_sel=000 -> ALU result",
                 3'b000,
                 32'hAAAA_AAAA,
                 32'hBBBB_BBBB,
                 32'h0000_0044,
                 32'h1234_5000,
                 32'h0000_1000,
                 32'hAAAA_AAAA);

        //=========================================================
        // wb_sel = 001 -> MEM
        //=========================================================
        run_test("wb_sel=001 -> Memory data",
                 3'b001,
                 32'hAAAA_AAAA,
                 32'hBBBB_BBBB,
                 32'h0000_0044,
                 32'h1234_5000,
                 32'h0000_1000,
                 32'hBBBB_BBBB);

        //=========================================================
        // wb_sel = 010 -> PC+4
        //=========================================================
        run_test("wb_sel=010 -> PC+4",
                 3'b010,
                 32'hAAAA_AAAA,
                 32'hBBBB_BBBB,
                 32'h0000_0044,
                 32'h1234_5000,
                 32'h0000_1000,
                 32'h0000_0044);

        //=========================================================
        // wb_sel = 011 -> U-IMM (LUI)
        //=========================================================
        run_test("wb_sel=011 -> U-immediate (LUI)",
                 3'b011,
                 32'hAAAA_AAAA,
                 32'hBBBB_BBBB,
                 32'h0000_0044,
                 32'h1234_5000,
                 32'h0000_1000,
                 32'h1234_5000);

        //=========================================================
        // wb_sel = 100 -> PC+IMM (AUIPC)
        //=========================================================
        run_test("wb_sel=100 -> PC+imm (AUIPC)",
                 3'b100,
                 32'hAAAA_AAAA,
                 32'hBBBB_BBBB,
                 32'h0000_0044,
                 32'h1234_5000,
                 32'h0000_1000,
                 32'h0000_1000);

        //=========================================================
        // Invalid wb_sel -> safe 0
        //=========================================================
        run_test("wb_sel invalid -> wb_data must be 0",
                 3'b111,
                 32'hAAAA_AAAA,
                 32'hBBBB_BBBB,
                 32'h0000_0044,
                 32'h1234_5000,
                 32'h0000_1000,
                 32'h0000_0000);

        //=========================================================
        // Final Summary Report
        //=========================================================
        $display("====================================================");
        $display(" WB_MUX VERIFICATION REPORT");
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
